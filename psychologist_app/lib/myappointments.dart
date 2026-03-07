import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // ── Lavender Palette ───────────────────────────────────────────────────────
  static const Color primaryPurple = Color(0xFF673AB7);
  static const Color deepPurple = Color(0xFF2D1B5E);
  static const Color lightLavender = Color(0xFFF1EEFA);
  static const Color rule = Color(0xFFE6DDF5);
  static const Color inkMuted = Color(0xFF7B6A9A);

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
          bottom: const TabBar(
            indicatorColor: primaryPurple,
            labelColor: primaryPurple,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryPurple),
              )
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
        final String type = appt['appointment_type']?.toString() ?? '0';

        // Fetch Token Data from Database
        final String tokenData = appt['token_number']?.toString() ?? "N/A";

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
            type: type,
            tokenData: tokenData,
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
    required String tokenData,
  }) {
    Color statusColor;
    String statusText;

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

    String typeLabel = (type == '1') ? "Online" : "Offline";
    IconData typeIcon = (type == '1')
        ? Icons.videocam_outlined
        : Icons.location_on_outlined;

    return Container(
      clipBehavior:
          Clip.antiAlias, // Ensures internal content follows border radius
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Section (Details)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: lightLavender,
                      child: const Icon(Icons.person, color: primaryPurple),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            parentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$date | $time",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildMiniBadge(statusText, statusColor),
                              const SizedBox(width: 8),
                              Icon(typeIcon, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Section (Token Display - matching your sketch)
            Container(
              width: 75,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F6FD),
                border: const Border(left: BorderSide(color: rule)),
              ),
              child: Center(
                child: Text(
                  tokenData, // Shows "TKN 10" exactly as in data
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepPurple,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
