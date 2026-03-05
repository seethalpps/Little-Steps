import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
// Ensure this path matches your project structure
import 'package:psychologist_app/viewparent.dart';

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

  final Color primaryPurple = const Color(0xFF673AB7);
  final Color lightLavender = const Color(0xFFF1EEFA);

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_appointment')
          .select('*, parent:tbl_parent(*)')
          .eq('psychologist_id', user.id)
          .order('appointment_date', ascending: true);

      final List<dynamic> data = response;
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      if (mounted) {
        setState(() {
          upcomingAppointments = data
              .where((appt) {
                final dateStr = appt['appointment_date'];
                final date = DateTime.parse(dateStr);
                return date.isAfter(now) || dateStr == todayStr;
              })
              .toList()
              .cast<Map<String, dynamic>>();

          previousAppointments = data
              .where((appt) {
                final dateStr = appt['appointment_date'];
                final date = DateTime.parse(dateStr);
                return date.isBefore(now) && dateStr != todayStr;
              })
              .toList()
              .cast<Map<String, dynamic>>();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
        ).showSnackBar(const SnackBar(content: Text("Session removed")));
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
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "My Sessions",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: primaryPurple,
            labelColor: primaryPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryPurple))
            : TabBarView(
                children: [
                  _buildListView(
                    upcomingAppointments,
                    "No upcoming sessions",
                    true,
                  ),
                  _buildListView(
                    previousAppointments,
                    "No past sessions",
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
    bool canDelete,
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
        final parentData = appt['parent'];
        final appointmentId = appt['appointment_id'].toString();
        final String status = appt['appointment_status']?.toString() ?? '0';

        // Handling the appointment type logic
        final String type = appt['appointment_type']?.toString() ?? '0';

        DateTime date = DateTime.parse(appt['appointment_date']);
        String formattedDate = DateFormat('EEE, MMM d').format(date);

        Widget card = InkWell(
          onTap: () async {
            if (parentData != null) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Viewparent(
                    parentData: parentData,
                    appointmentId: appointmentId,
                  ),
                ),
              );
              if (result == true) fetchAppointments();
            }
          },
          child: _buildAppointmentCard(
            parentName: parentData?['parent_name'] ?? "Parent",
            date: formattedDate,
            time: appt['appointment_time'] ?? "00:00",
            status: status,
            type: type, // Passing type to card
          ),
        );

        if (canDelete) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: Dismissible(
              key: Key(appointmentId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (dir) => _showConfirmDialog(),
              onDismissed: (dir) => _deleteAppointment(appointmentId),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: card,
            ),
          );
        }
        return Padding(padding: const EdgeInsets.only(bottom: 15), child: card);
      },
    );
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text(
          "This will remove this appointment record permanently.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard({
    required String parentName,
    required String date,
    required String time,
    required String status,
    required String type,
  }) {
    Color statusColor;
    String statusText;

    // Status logic
    switch (status) {
      case '1':
        statusColor = Colors.green;
        statusText = "Accepted";
        break;
      case '2':
        statusColor = Colors.red;
        statusText = "Rejected";
        break;
      default:
        statusColor = Colors.orange;
        statusText = "Pending";
    }

    // Type logic: 0 = Offline, 1 = Online
    String typeLabel = (type == '1') ? "Online" : "Offline";
    IconData typeIcon = (type == '1')
        ? Icons.videocam_outlined
        : Icons.location_on_outlined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: lightLavender,
            child: Icon(Icons.person, color: primaryPurple),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Type Badge (Offline/Online)
                    Row(
                      children: [
                        Icon(typeIcon, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(
                  color: primaryPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
