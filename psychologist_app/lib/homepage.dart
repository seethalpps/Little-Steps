import 'package:flutter/material.dart';
import 'package:psychologist_app/myappointments.dart';
import 'package:psychologist_app/myprofile.dart';
import 'package:psychologist_app/reportchart.dart';
import 'package:psychologist_app/myappointments.dart'; // 1. Added this import
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? psychData;
  List<Map<String, dynamic>> todayAppointments = [];

  Set<String> _leaveDates = {};
  Set<String> _appointmentDates = {};

  bool _isLoading = true;
  bool _isAppointmentsLoading = false;
  bool _isLeaveDay = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Color primaryPurple = const Color.fromRGBO(61, 14, 86, 1);
  final Color appointmentGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _initialFetch();
  }

  Future<void> _initialFetch() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAllLeaveDates(),
      _fetchAllAppointmentDates(),
      _fetchDashboardData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAllLeaveDates() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final List<dynamic> data = await supabase
          .from('tbl_leave')
          .select('leave_date')
          .eq('psychologist_id', user.id)
          .eq('leave_status', '1');

      setState(() {
        _leaveDates = data.map((d) => d['leave_date'].toString()).toSet();
      });
    } catch (e) {
      debugPrint("Leave Fetch Error: $e");
    }
  }

  Future<void> _fetchAllAppointmentDates() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final List<dynamic> data = await supabase
          .from('tbl_appointment')
          .select('appointment_date')
          .eq('psychologist_id', user.id);

      setState(() {
        _appointmentDates = data
            .map((d) => d['appointment_date'].toString())
            .toSet();
      });
    } catch (e) {
      debugPrint("Appointment Marker Fetch Error: $e");
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final String targetDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      if (psychData == null) {
        psychData = await supabase
            .from('tbl_psychologist')
            .select()
            .eq('psychologist_id', user.id)
            .single();
      }

      final List<dynamic> appointments = await supabase
          .from('tbl_appointment')
          .select('*, tbl_parent(parent_name, parent_photo)')
          .eq('psychologist_id', user.id)
          .eq('appointment_date', targetDate)
          .order('appointment_time', ascending: true);

      if (mounted) {
        setState(() {
          _isLeaveDay = _leaveDates.contains(targetDate);
          todayAppointments = List<Map<String, dynamic>>.from(appointments);
          _isAppointmentsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
      if (mounted) setState(() => _isAppointmentsLoading = false);
    }
  }

  Future<void> _toggleLeave() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDay!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot modify leave for past dates")),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;
    final String leaveDate = DateFormat('yyyy-MM-dd').format(_selectedDay!);

    try {
      if (_isLeaveDay) {
        await supabase
            .from('tbl_leave')
            .delete()
            .eq('psychologist_id', user.id)
            .eq('leave_date', leaveDate);
        setState(() => _leaveDates.remove(leaveDate));
      } else {
        await supabase.from('tbl_leave').upsert({
          'psychologist_id': user.id,
          'leave_date': leaveDate,
          'leave_status': '1',
        });
        setState(() => _leaveDates.add(leaveDate));
      }
      _fetchDashboardData();
    } catch (e) {
      debugPrint("Toggle Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _initialFetch,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 25),
                      _buildCalendarCard(),
                      const SizedBox(height: 30),
                      _buildSectionTitle("Quick Actions"),
                      const SizedBox(height: 15),
                      _buildQuickActions(),
                      const SizedBox(height: 30),
                      _buildSectionTitle(
                        "Schedule: ${DateFormat('dd MMM').format(_selectedDay!)}",
                      ),
                      const SizedBox(height: 15),
                      _isAppointmentsLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: primaryPurple,
                              ),
                            )
                          : _buildAppointmentList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hello,",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              "Dr. ${psychData?['psychologist_name']?.split(' ')[0] ?? 'Expert'}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Myprofile()),
          ),
          child: CircleAvatar(
            radius: 25,
            backgroundColor: primaryPurple.withOpacity(0.1),
            backgroundImage: psychData?['psychologist_photo'] != null
                ? NetworkImage(psychData!['psychologist_photo'])
                : null,
            child: psychData?['psychologist_photo'] == null
                ? Icon(Icons.person, color: primaryPurple)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              prioritizedBuilder: (context, day, focusedDay) {
                final dateKey = DateFormat('yyyy-MM-dd').format(day);
                bool isSelected = isSameDay(_selectedDay, day);
                bool isLeave = _leaveDates.contains(dateKey);
                bool hasAppointment = _appointmentDates.contains(dateKey);
                bool isPast = day.isBefore(today);

                return Opacity(
                  opacity: isPast ? 0.5 : 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(6.0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasAppointment
                          ? appointmentGreen
                          : (isLeave
                                ? Colors.red.shade400
                                : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: primaryPurple, width: 2)
                          : null,
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: (hasAppointment || isLeave)
                            ? Colors.white
                            : (isPast ? Colors.grey : Colors.black),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _isAppointmentsLoading = true;
              });
              _fetchDashboardData();
            },
          ),
          const Divider(height: 20),
          if (!_selectedDay!.isBefore(today))
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _toggleLeave,
                icon: Icon(
                  _isLeaveDay ? Icons.check_circle : Icons.event_busy,
                  color: _isLeaveDay ? Colors.green : Colors.redAccent,
                ),
                label: Text(
                  _isLeaveDay ? "Cancel Leave" : "Mark Leave",
                  style: TextStyle(
                    color: _isLeaveDay ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Past date cannot be modified",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionBtn(Icons.people, "Patients", Colors.blue, () {
          // Future navigation
        }),
        _buildActionBtn(Icons.chat_bubble, "Messages", Colors.orange, () {
          // Future navigation
        }),
        _buildActionBtn(Icons.insert_chart, "Reports", Colors.green, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportChart()),
          );
        }),
        _buildActionBtn(Icons.videocam, "Appointments", Colors.red, () {
          // 2. Navigation to Appointments page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Myappointments()),
          );
        }),
      ],
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList() {
    if (todayAppointments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "No appointments for this day",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: todayAppointments.map((appt) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryPurple.withOpacity(0.1),
                backgroundImage: appt['tbl_parent']?['parent_photo'] != null
                    ? NetworkImage(appt['tbl_parent']['parent_photo'])
                    : null,
                child: appt['tbl_parent']?['parent_photo'] == null
                    ? Text(
                        appt['tbl_parent']?['parent_name']?[0] ?? "P",
                        style: TextStyle(color: primaryPurple),
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt['tbl_parent']?['parent_name'] ?? "Parent Name",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      appt['appointment_time'] ?? "Time not set",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
