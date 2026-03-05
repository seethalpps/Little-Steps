import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Myappointments extends StatefulWidget {
  const Myappointments({super.key});

  @override
  State<Myappointments> createState() => _MyappointmentsState();
}

class _MyappointmentsState extends State<Myappointments> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> previousAppointments = [];
  bool _isLoading = true;

  final Color primaryPurple = const Color(0xFF6A4BC1);
  final Color lightLavender = const Color(0xFFF1EEFA);

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_appointment')
          .select(
            '*, psychologist:tbl_psychologist(psychologist_name, psychologist_photo, psychologist_qualification)',
          )
          .eq('parent_id', user.id)
          .order('appointment_date', ascending: true);

      final List<dynamic> data = response;
      final now = DateTime.now();

      setState(() {
        upcomingAppointments = data
            .where((appt) {
              final date = DateTime.parse(appt['appointment_date']);
              return date.isAfter(now) ||
                  DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(now);
            })
            .toList()
            .cast<Map<String, dynamic>>();

        previousAppointments = data
            .where((appt) {
              final date = DateTime.parse(appt['appointment_date']);
              return date.isBefore(now) &&
                  DateFormat('yyyy-MM-dd').format(date) !=
                      DateFormat('yyyy-MM-dd').format(now);
            })
            .toList()
            .cast<Map<String, dynamic>>();

        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Cancel Appointment"),
          content: const Text(
            "Are you sure you want to delete this appointment?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                "Yes, Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      await supabase
          .from('tbl_appointment')
          .delete()
          .eq('appointment_id', appointmentId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Appointment deleted")));
        fetchAppointments();
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBF9FF),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Appointments",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          bottom: TabBar(
            indicatorColor: primaryPurple,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Upcoming"),
              Tab(text: "Previous"),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryPurple))
            : TabBarView(
                children: [
                  _buildListView(
                    upcomingAppointments,
                    "No upcoming appointments",
                    true,
                  ),
                  _buildListView(
                    previousAppointments,
                    "No previous appointments",
                    false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildListView(
    List<Map<String, dynamic>> list,
    String emptyMsg,
    bool isUpcoming,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appt = list[index];
        final psychologist = appt['psychologist'];
        final appointmentId = appt['appointment_id'].toString();

        // LOGIC: 1 = Online, 0 = Offline
        final int typeValue =
            int.tryParse(appt['appointment_type'].toString()) ?? 0;
        final String appTypeText = (typeValue == 1) ? "Online" : "Offline";

        final int status =
            int.tryParse(appt['appointment_status'].toString()) ?? 0;

        String dayDate = "N/A";
        if (appt['appointment_date'] != null) {
          DateTime date = DateTime.parse(appt['appointment_date']);
          dayDate = DateFormat('EEEE, MMM d').format(date);
        }

        Widget card = _buildAppointmentCard(
          name: psychologist['psychologist_name'] ?? "Unknown",
          qualification:
              psychologist['psychologist_qualification'] ??
              "Clinical Psychologist",
          dayDate: dayDate,
          time: appt['appointment_time'] ?? "00:00",
          photoUrl: psychologist['psychologist_photo'],
          status: status,
          appointmentTypeText: appTypeText, // Online or Offline
          isOnline: typeValue == 1, // To determine color
          showStatus: isUpcoming,
        );

        if (isUpcoming) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Dismissible(
              key: Key(appointmentId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _showDeleteConfirmation(context),
              onDismissed: (direction) => _deleteAppointment(appointmentId),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 25),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 28),
              ),
              child: card,
            ),
          );
        }

        return Padding(padding: const EdgeInsets.only(bottom: 15), child: card);
      },
    );
  }

  Widget _buildAppointmentCard({
    required String name,
    required String qualification,
    required String dayDate,
    required String time,
    required int status,
    required bool showStatus,
    required String appointmentTypeText,
    required bool isOnline,
    String? photoUrl,
  }) {
    Color statusColor = status == 1 ? Colors.green : Colors.orange;
    String statusText = status == 1 ? "Accepted" : "Pending";

    // Online uses Primary Purple, Offline uses Grey
    Color typeColor = isOnline ? primaryPurple : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  qualification,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // --- Online/Offline Badge ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        appointmentTypeText,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 8),
                      // --- Status Badge ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 7, color: statusColor),
                            const SizedBox(width: 5),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: lightLavender,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  dayDate,
                  style: TextStyle(
                    color: primaryPurple.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
