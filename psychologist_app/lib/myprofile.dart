import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

// Ensure these imports match your project structure
import 'package:psychologist_app/availabledate_time.dart';
import 'package:psychologist_app/myappointments.dart';
import 'package:psychologist_app/editavailability.dart';
import 'package:psychologist_app/settings.dart';
import 'package:psychologist_app/editprofile.dart';

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});

  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? psychData;
  bool _isLoading = true;

  // Analytics stats
  int patientCount = 0;
  int onlineCount = 0;
  int offlineCount = 0;

  // Selected date state
  DateTime _selectedDate = DateTime.now();

  // List to store dates where the psychologist is on leave
  List<DateTime> leaveDates = [];

  final Color primaryPurple = const Color(0xFF673AB7);
  final Color leaveRed = const Color(0xFFE57373);

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  /// Fetches profile, analytics, and leaves in parallel
  Future<void> fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([fetchProfile(), fetchAnalytics(), fetchLeaves()]);
    if (mounted) setState(() => _isLoading = false);
  }

  /// Fetches basic psychologist profile details
  Future<void> fetchProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('tbl_psychologist')
          .select()
          .eq('psychologist_id', user.id)
          .single();
      setState(() => psychData = data);
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  /// Fetches leave dates from tbl_leave
  Future<void> fetchLeaves() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_leave')
          .select('leave_date')
          .eq('psychologist_id', user.id);

      final List data = response as List;
      setState(() {
        leaveDates = data.map((item) {
          // Assuming leave_date is stored as YYYY-MM-DD or ISO string
          return DateTime.parse(item['leave_date']);
        }).toList();
      });
    } catch (e) {
      debugPrint("Error fetching leaves: $e");
    }
  }

  /// Fetches real-time counts for the selected month
  Future<void> fetchAnalytics() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final firstDayOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        1,
      ).toIso8601String();
      final lastDayOfMonth = DateTime(
        _selectedDate.year,
        _selectedDate.month + 1,
        0,
        23,
        59,
        59,
      ).toIso8601String();

      final response = await supabase
          .from('tbl_appointment')
          .select('appointment_type')
          .eq('psychologist_id', user.id)
          .gte('appointment_date', firstDayOfMonth)
          .lte('appointment_date', lastDayOfMonth);

      final List data = response as List;

      final online = data
          .where((item) => item['appointment_type'] == 'Online')
          .length;
      final offline = data
          .where((item) => item['appointment_type'] == 'Offline')
          .length;

      setState(() {
        onlineCount = online;
        offlineCount = offline;
        patientCount = online + offline;
      });
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Settings()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : RefreshIndicator(
              onRefresh: fetchInitialData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 25),
                    _buildEarningsCard(),
                    const SizedBox(height: 25),
                    _buildSectionTitle(
                      "${DateFormat('MMMM').format(_selectedDate)} Overview",
                    ),
                    const SizedBox(height: 15),
                    _buildAnalyticsGrid(),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("My Availability"),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Editavailability(),
                              ),
                            ).then((_) => fetchInitialData());
                          },
                          icon: Icon(
                            Icons.arrow_circle_right_outlined,
                            color: primaryPurple,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      "Select a date to set your available hours. Red indicates leave.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    _buildAvailabilityPicker(),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionTitle("Sessions"),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Myappointments(),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.arrow_circle_right_outlined,
                            color: primaryPurple,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: const Color(0xFFEDE7F6),
          backgroundImage: psychData?['psychologist_photo'] != null
              ? NetworkImage(psychData!['psychologist_photo'])
              : null,
          child: psychData?['psychologist_photo'] == null
              ? Icon(Icons.psychology, color: primaryPurple, size: 30)
              : null,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                psychData?['psychologist_name'] ?? "Name",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                psychData?['psychologist_email'] ?? "Email",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Editprofile()),
            ).then((_) => fetchInitialData());
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            "Patients",
            patientCount.toString(),
            Icons.people_outline,
            Colors.blue,
          ),
          _buildStatDivider(),
          _buildStatItem(
            "Online",
            onlineCount.toString(),
            Icons.videocam_outlined,
            Colors.orange,
          ),
          _buildStatDivider(),
          _buildStatItem(
            "Offline",
            offlineCount.toString(),
            Icons.location_on_outlined,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatDivider() =>
      Container(height: 30, width: 1, color: Colors.grey.shade300);

  Widget _buildEarningsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryPurple, Colors.deepPurple.shade400],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Earnings",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                "₹",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                psychData?['earnings']?.toString() ?? "0.00",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityPicker() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));

          // Check if this specific date matches any date in our leave list
          bool isLeave = leaveDates.any(
            (d) =>
                d.year == date.year &&
                d.month == date.month &&
                d.day == date.day,
          );

          bool isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month;

          return GestureDetector(
            onTap: isLeave
                ? null // Disable selection if on leave
                : () {
                    bool monthChanged =
                        date.month != _selectedDate.month ||
                        date.year != _selectedDate.year;
                    setState(() => _selectedDate = date);
                    if (monthChanged) fetchAnalytics();

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AvailabledateTime(selectedDate: date),
                      ),
                    );
                  },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                // Priority: Leave color (Red) > Selected color (Purple) > Default (Grey)
                color: isLeave
                    ? leaveRed
                    : (isSelected ? primaryPurple : const Color(0xFFF5F5F5)),
                borderRadius: BorderRadius.circular(15),
                boxShadow: isSelected && !isLeave
                    ? [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLeave ? "OFF" : DateFormat('EEE').format(date),
                    style: TextStyle(
                      color: (isSelected || isLeave)
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 11,
                      fontWeight: isLeave ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: (isSelected || isLeave)
                          ? Colors.white
                          : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
