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
  // ────────────────────────────────────────────────────────────────────────────

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
                "Are you sure you want to cancel this appointment? This cannot be undone.",
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
            content: const Text(
              "Appointment cancelled",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
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
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: rule),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: primary,
                size: 15,
              ),
            ),
          ),
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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: rule),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deep, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: inkMuted,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
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
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: TabBarView(
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
            ),
    );
  }

  // ─── LIST VIEW ───────────────────────────────────────────────────────────────

  Widget _buildListView(
    List<Map<String, dynamic>> list,
    String emptyMsg,
    bool isUpcoming,
  ) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: soft.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUpcoming
                    ? Icons.calendar_today_outlined
                    : Icons.history_rounded,
                size: 36,
                color: primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              emptyMsg,
              style: const TextStyle(
                color: inkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appt = list[index];
        final psychologist = appt['psychologist'];
        final appointmentId = appt['appointment_id'].toString();
        final int typeValue =
            int.tryParse(appt['appointment_type'].toString()) ?? 0;
        final String appTypeText = typeValue == 1 ? "Online" : "Offline";
        final int status =
            int.tryParse(appt['appointment_status'].toString()) ?? 0;

        String dayDate = "N/A";
        String dayNum = "";
        String monthStr = "";
        if (appt['appointment_date'] != null) {
          final date = DateTime.parse(appt['appointment_date']);
          dayDate = DateFormat('EEE, MMM d').format(date);
          dayNum = DateFormat('d').format(date);
          monthStr = DateFormat('MMM').format(date);
        }

        final card = _buildAppointmentCard(
          name: psychologist['psychologist_name'] ?? "Unknown",
          qualification:
              psychologist['psychologist_qualification'] ??
              "Clinical Psychologist",
          photoUrl: psychologist['psychologist_photo'],
          dayDate: dayDate,
          dayNum: dayNum,
          monthStr: monthStr,
          time: appt['appointment_time'] ?? "00:00",
          status: status,
          showStatus: isUpcoming,
          appointmentTypeText: appTypeText,
          isOnline: typeValue == 1,
        );

        if (isUpcoming) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Dismissible(
              key: Key(appointmentId),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _showDeleteConfirmation(),
              onDismissed: (_) => _deleteAppointment(appointmentId),
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
                  size: 26,
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

  // ─── APPOINTMENT CARD ────────────────────────────────────────────────────────

  Widget _buildAppointmentCard({
    required String name,
    required String qualification,
    required String dayDate,
    required String dayNum,
    required String monthStr,
    required String time,
    required int status,
    required bool showStatus,
    required String appointmentTypeText,
    required bool isOnline,
    String? photoUrl,
  }) {
    // Status
    final Color statusColor = status == 1
        ? const Color(0xFF3D9A6B)
        : const Color(0xFFD4820A);
    final Color statusBg = status == 1
        ? const Color(0xFFDFF5EC)
        : const Color(0xFFFFF3DC);
    final String statusText = status == 1 ? "Accepted" : "Pending";

    // Type
    final Color typeColor = isOnline ? primary : const Color(0xFF5B8FA8);
    final Color typeBg = isOnline ? soft : const Color(0xFFDCEEF6);

    // Initials fallback
    final initials = name
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // ── Date block ─────────────────────────────────────────────────────
          Container(
            width: 52,
            height: 62,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [deep, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNum,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  monthStr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ───────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: inkDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  qualification,
                  style: const TextStyle(color: inkMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline
                                ? Icons.videocam_outlined
                                : Icons.location_on_outlined,
                            size: 10,
                            color: typeColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            appointmentTypeText,
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: 6),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
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
          const SizedBox(width: 10),

          // ── Avatar + time ──────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [medium, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.network(photoUrl, fit: BoxFit.cover),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: surface,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              // Time pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 10,
                      color: primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      time,
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
