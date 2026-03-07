import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Myappointments extends StatefulWidget {
  const Myappointments({super.key});

  @override
  State<Myappointments> createState() => _MyappointmentsState();
}

class _MyappointmentsState extends State<Myappointments>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> previousAppointments = [];
  bool _isLoading = true;

  // ── Soft Lavender Palette ────────────────────────────────────────────────────
  static const Color deep = Color(0xFF2D1B5E);
  static const Color primary = Color(0xFF7B5EA7);
  static const Color medium = Color(0xFFA688D4);
  static const Color soft = Color(0xFFD4C4EE);
  static const Color background = Color(0xFFF0EBF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inkDark = Color(0xFF2D1B5E);
  static const Color inkMuted = Color(0xFF7B6A9A);
  static const Color rule = Color(0xFFE6DDF5);
  static const Color danger = Color(0xFF9B3A5A);

  late TabController _tabController;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animController.dispose();
    super.dispose();
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
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      setState(() {
        upcomingAppointments = data
            .where((appt) {
              final date = DateTime.parse(appt['appointment_date']);
              return date.isAfter(now) ||
                  DateFormat('yyyy-MM-dd').format(date) == todayStr;
            })
            .toList()
            .cast<Map<String, dynamic>>();

        previousAppointments = data
            .where((appt) {
              final date = DateTime.parse(appt['appointment_date']);
              return date.isBefore(now) &&
                  DateFormat('yyyy-MM-dd').format(date) != todayStr;
            })
            .toList()
            .cast<Map<String, dynamic>>();

        _isLoading = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Cancel Appointment",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: inkDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to cancel this appointment?",
                textAlign: TextAlign.center,
                style: TextStyle(color: inkMuted, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rule),
                        ),
                        child: const Center(
                          child: Text(
                            "Keep",
                            style: TextStyle(
                              color: inkMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAppointment(String appointmentId) async {
    try {
      await supabase
          .from('tbl_appointment')
          .delete()
          .eq('appointment_id', appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Appointment cancelled"),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        fetchAppointments();
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Appointments",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rule),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(colors: [deep, primary]),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: inkMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                tabs: const [
                  Tab(text: "Upcoming"),
                  Tab(text: "Previous"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
              controller: _tabController,
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
    );
  }

  Widget _buildListView(
    List<Map<String, dynamic>> list,
    String emptyMsg,
    bool isUpcoming,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: inkMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appt = list[index];
        final psychologist = appt['psychologist'];

        // This pulls "TKN 10" directly from your data column
        final String tokenValue = appt['token_number']?.toString() ?? "N/A";

        final int typeValue =
            int.tryParse(appt['appointment_type'].toString()) ?? 0;
        final int status =
            int.tryParse(appt['appointment_status'].toString()) ?? 0;

        String dayNum = "";
        String monthStr = "";
        if (appt['appointment_date'] != null) {
          final date = DateTime.parse(appt['appointment_date']);
          dayNum = DateFormat('d').format(date);
          monthStr = DateFormat('MMM').format(date);
        }

        final card = _buildAppointmentCard(
          name: psychologist['psychologist_name'] ?? "Unknown",
          qualification:
              psychologist['psychologist_qualification'] ??
              "Clinical Psychologist",
          dayNum: dayNum,
          monthStr: monthStr,
          time: appt['appointment_time'] ?? "00:00",
          status: status,
          showStatus: isUpcoming,
          appointmentTypeText: typeValue == 1 ? "Online" : "Offline",
          isOnline: typeValue == 1,
          tokenData: tokenValue,
        );

        if (isUpcoming) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Dismissible(
              key: Key(appt['appointment_id'].toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _showDeleteConfirmation(),
              onDismissed: (_) =>
                  _deleteAppointment(appt['appointment_id'].toString()),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                decoration: BoxDecoration(
                  color: danger,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                ),
              ),
              child: card,
            ),
          );
        }
        return Padding(padding: const EdgeInsets.only(bottom: 14), child: card);
      },
    );
  }

  Widget _buildAppointmentCard({
    required String name,
    required String qualification,
    required String dayNum,
    required String monthStr,
    required String time,
    required int status,
    required bool showStatus,
    required String appointmentTypeText,
    required bool isOnline,
    required String tokenData,
  }) {
    final Color statusColor = status == 1
        ? const Color(0xFF3D9A6B)
        : const Color(0xFFD4820A);
    final Color statusBg = status == 1
        ? const Color(0xFFDFF5EC)
        : const Color(0xFFFFF3DC);
    final Color typeColor = isOnline ? primary : const Color(0xFF5B8FA8);
    final Color typeBg = isOnline ? soft : const Color(0xFFDCEEF6);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [deep, primary]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNum,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            monthStr.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: inkDark,
                            ),
                          ),
                          Text(
                            qualification,
                            style: const TextStyle(
                              color: inkMuted,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _buildBadge(
                                appointmentTypeText,
                                typeBg,
                                typeColor,
                                isOnline
                                    ? Icons.videocam_outlined
                                    : Icons.location_on_outlined,
                              ),
                              if (showStatus)
                                _buildBadge(
                                  status == 1 ? "Accepted" : "Pending",
                                  statusBg,
                                  statusColor,
                                  Icons.circle,
                                  iconSize: 6,
                                ),
                              _buildBadge(
                                time,
                                soft,
                                primary,
                                Icons.schedule_rounded,
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
            // Right Token Section (Displays data exactly as provided)
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: background.withOpacity(0.4),
                border: const Border(left: BorderSide(color: rule)),
              ),
              child: Center(
                child: Text(
                  tokenData, // This will show "TKN 10" or whatever is in your DB
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primary,
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

  Widget _buildBadge(
    String text,
    Color bg,
    Color textCol,
    IconData icon, {
    double iconSize = 10,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: textCol),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              color: textCol,
              fontWeight: FontWeight.w800,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
