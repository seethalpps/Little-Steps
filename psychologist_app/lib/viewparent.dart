import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Viewparent extends StatefulWidget {
  final Map<String, dynamic> parentData;
  final String appointmentId;

  const Viewparent({
    super.key,
    required this.parentData,
    required this.appointmentId,
  });

  @override
  State<Viewparent> createState() => _ViewparentState();
}

class _ViewparentState extends State<Viewparent> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> childrens = [];
  List<dynamic> pastAppointments = [];

  bool _isLoading = true;
  bool _isUpdating = false;

  final Color primaryPurple = const Color(0xFF673AB7);

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  String _calculateAge(String? dobString) {
    if (dobString == null || dobString.isEmpty) return 'N/A';
    try {
      DateTime dob = DateTime.parse(dobString);
      DateTime now = DateTime.now();

      int age = now.year - dob.year;

      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      return "$age Years";
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _fetchDetails() async {
    try {
      final parentId = widget.parentData['parent_id'].toString();

      final results = await Future.wait([
        supabase
            .from('tbl_child')
            .select('child_name, child_dob, child_notes')
            .eq('parent_id', parentId),
        supabase
            .from('tbl_appointment')
            .select('appointment_date, appointment_time')
            .eq('parent_id', parentId)
            .eq('appointment_status', '1')
            .lt('appointment_date', DateTime.now().toIso8601String())
            .order('appointment_date', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          childrens = results[0];
          pastAppointments = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// SEND NOTIFICATION TO PARENT
  Future<void> _sendNotification(String status) async {
    try {
      final parentId = widget.parentData['parent_id'];

      String title = status == '1' ? "Booking Accepted! 🎉" : "Booking Update";
      String message = status == '1'
          ? "Your appointment has been accepted by the psychologist."
          : "Your appointment has been rejected by the psychologist.";

      // Matching the table structure for the NotificationPage
      await supabase.from('tbl_notification').insert({
        'parent_id': parentId,
        'notification_title': title,
        'notification_message': message,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint("Notification successfully sent to parent.");
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  /// UPDATE APPOINTMENT STATUS
  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);

    try {
      // 1. Update Appointment Table
      await supabase
          .from('tbl_appointment')
          .update({
            'appointment_status': status,
          })
          .eq('appointment_id', widget.appointmentId);

      // 2. Send Notification Row
      await _sendNotification(status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == '1'
                  ? "Appointment Accepted & Parent Notified"
                  : "Appointment Declined",
            ),
            backgroundColor: status == '1' ? Colors.green : Colors.red,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("Update error: $e");
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Parent Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryPurple,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const Divider(height: 40),
                  _buildSectionTitle("Contact Information"),
                  _buildInfoTile(
                    Icons.email_outlined,
                    "Email",
                    widget.parentData['parent_email'],
                  ),
                  _buildInfoTile(
                    Icons.phone_outlined,
                    "Contact",
                    widget.parentData['parent_contact'],
                  ),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Child Details"),
                  _buildChildrensList(),
                  const SizedBox(height: 30),
                  _buildSectionTitle("Previous Appointments"),
                  _buildPastAppointments(),
                  const SizedBox(height: 120), // Space for bottom buttons
                ],
              ),
            ),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildProfileHeader() {
    final photo = widget.parentData['parent_photo'];
    final bool hasValidPhoto =
        photo != null && photo.toString().startsWith('http');

    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFF1EEFA),
            backgroundImage: hasValidPhoto ? NetworkImage(photo) : null,
            child: !hasValidPhoto
                ? Icon(Icons.person, size: 50, color: primaryPurple)
                : null,
          ),
          const SizedBox(height: 15),
          Text(
            widget.parentData['parent_name'] ?? "Unknown Parent",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: primaryPurple),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      subtitle: Text(
        value ?? "Not provided",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChildrensList() {
    if (childrens.isEmpty) {
      return const Text(
        "No children records found.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: childrens.map((child) {
        return Card(
          color: const Color(0xFFFBF9FF),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primaryPurple.withOpacity(0.1),
                      child: Icon(Icons.child_care, color: primaryPurple),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child['child_name'] ?? "Child",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text("Age: ${_calculateAge(child['child_dob'])}"),
                      ],
                    ),
                  ],
                ),
                if (child['child_notes'] != null) ...[
                  const Divider(),
                  const Text(
                    "Child Notes:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey),
                  ),
                  Text(child['child_notes']),
                ]
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPastAppointments() {
    if (pastAppointments.isEmpty) {
      return const Text("No previous history recorded.",
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: pastAppointments.map((appt) {
        DateTime date = DateTime.parse(appt['appointment_date']);

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.blueGrey),
            title: Text(DateFormat('MMM d, yyyy').format(date)),
            subtitle: Text("Time: ${appt['appointment_time']}"),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isUpdating ? null : () => _updateStatus('2'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Decline"),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: ElevatedButton(
              onPressed: _isUpdating ? null : () => _updateStatus('1'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}