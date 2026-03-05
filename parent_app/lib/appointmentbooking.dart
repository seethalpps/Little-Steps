import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class Appointmentbooking extends StatefulWidget {
  final Map<String, dynamic>? psychologistData;
  const Appointmentbooking({super.key, this.psychologistData});

  @override
  State<Appointmentbooking> createState() => _AppointmentbookingState();
}

class _AppointmentbookingState extends State<Appointmentbooking>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _isFetchingInitial = true;
  bool _isFetchingSlots = false;

  List<String> _availableDates = [];
  List<String> _availableSlots = [];
  List<String> _childrenNames = [];

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedCalendarDay;
  String? _selectedTime;
  String? _selectedChild;
  String _appointmentType = 'Offline'; // Default

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color deep = Color(0xFF2D1B5E);
  static const Color primary = Color(0xFF7B5EA7);
  static const Color medium = Color(0xFFA688D4);
  static const Color soft = Color(0xFFD4C4EE);
  static const Color background = Color(0xFFF0EBF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color inkDark = Color(0xFF2D1B5E);
  static const Color inkMuted = Color(0xFF7B6A9A);
  static const Color rule = Color(0xFFE6DDF5);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fetchInitialData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isFetchingInitial = true);
    // Fetch children once, and fetch dates based on default type (Offline)
    await Future.wait([
      _fetchPsychologistAvailability(_appointmentType),
      _fetchChildren(),
    ]);
    if (mounted) {
      setState(() => _isFetchingInitial = false);
      _animController.forward();
    }
  }

  Future<void> _fetchChildren() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;
      final response = await supabase
          .from('tbl_child')
          .select('child_name')
          .eq('parent_id', userId);
      setState(() {
        _childrenNames = (response as List)
            .map((e) => e['child_name'].toString())
            .toList();
      });
    } catch (e) {
      debugPrint("Error children: $e");
    }
  }

  // UPDATED: Now filters by appointment_type to update the calendar
  Future<void> _fetchPsychologistAvailability(String type) async {
    try {
      final psyId = widget.psychologistData?['psychologist_id'];
      final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final int typeInt = (type == 'Online') ? 1 : 0;

      final response = await supabase
          .from('tbl_availability')
          .select('available_date')
          .eq('psychologist_id', psyId)
          .eq('appointment_type', typeInt) // Filter dates by type
          .gte('available_date', today);

      final List data = response as List;
      setState(() {
        _availableDates = data
            .map((e) => e['available_date'].toString())
            .toList();
      });
    } catch (e) {
      debugPrint("Error dates: $e");
    }
  }

  Future<void> _fetchTimeSlots(String date) async {
    setState(() {
      _selectedTime = null;
      _availableSlots = [];
      _isFetchingSlots = true;
    });
    try {
      final psyId = widget.psychologistData?['psychologist_id'];
      final int typeInt = (_appointmentType == 'Online') ? 1 : 0;

      final response = await supabase
          .from('tbl_availability')
          .select('start_time, end_time')
          .eq('psychologist_id', psyId)
          .eq('available_date', date)
          .eq('appointment_type', typeInt);

      setState(() {
        _availableSlots = (response as List)
            .map((e) => "${e['start_time']} - ${e['end_time']}")
            .toList();
      });
    } catch (e) {
      debugPrint("Error slots: $e");
    } finally {
      if (mounted) setState(() => _isFetchingSlots = false);
    }
  }

  bool _isDayAvailable(DateTime day) {
    return _availableDates.contains(DateFormat('yyyy-MM-dd').format(day));
  }

  Future<void> _submitBooking() async {
    if (_selectedChild == null ||
        _selectedCalendarDay == null ||
        _selectedTime == null) {
      _showSnackBar("Please complete all selections", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await supabase.from('tbl_appointment').insert({
        'psychologist_id': widget.psychologistData?['psychologist_id'],
        'parent_id': supabase.auth.currentUser?.id,
        'child_name': _selectedChild,
        'appointment_date': DateFormat(
          'yyyy-MM-dd',
        ).format(_selectedCalendarDay!),
        'appointment_time': _selectedTime,
        'appointment_status': 0,
        'appointment_type': (_appointmentType == 'Online') ? 1 : 0,
      });
      if (mounted) {
        _showSnackBar("Booking request sent successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final psyName =
        widget.psychologistData?['psychologist_name'] ?? 'Therapist';
    final psyPhoto = widget.psychologistData?['psychologist_photo'];
    final psyQual =
        widget.psychologistData?['psychologist_qualification'] ?? '';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Book Session",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
      ),
      body: _isFetchingInitial
          ? const Center(child: CircularProgressIndicator(color: primary))
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPsychologistCard(psyName, psyPhoto, psyQual),
                      const SizedBox(height: 32),
                      _buildSectionRule("SELECT CHILD"),
                      const SizedBox(height: 14),
                      _buildChildDropdown(),
                      const SizedBox(height: 32),
                      _buildSectionRule("CONSULTATION TYPE"),
                      const SizedBox(height: 14),
                      _buildTypeToggle(),
                      const SizedBox(height: 32),
                      _buildSectionRule("SELECT DATE"),
                      const SizedBox(height: 14),
                      _buildCalendar(),
                      const SizedBox(height: 32),
                      if (_selectedCalendarDay != null) ...[
                        _buildSectionRule("AVAILABLE SLOTS"),
                        const SizedBox(height: 14),
                        _buildTimeSelector(),
                        const SizedBox(height: 32),
                      ],
                      _buildConfirmButton(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPsychologistCard(
    String name,
    String? photo,
    String qualification,
  ) {
    final initials = name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: medium,
            backgroundImage: photo != null ? NetworkImage(photo) : null,
            child: photo == null
                ? Text(initials, style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: inkDark,
                  ),
                ),
                Text(
                  qualification,
                  style: const TextStyle(fontSize: 12, color: inkMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRule(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: inkMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: rule)),
      ],
    );
  }

  Widget _buildChildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rule),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedChild,
          isExpanded: true,
          hint: const Text("Select child profile"),
          items: _childrenNames
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          onChanged: (val) => setState(() => _selectedChild = val),
        ),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        _buildTypeChip("Offline", Icons.location_on_outlined),
        const SizedBox(width: 12),
        _buildTypeChip("Online", Icons.videocam_outlined),
      ],
    );
  }

  Widget _buildTypeChip(String label, IconData icon) {
    final isSelected = _appointmentType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (_appointmentType == label) return; // No change

          setState(() {
            _appointmentType = label;
            _selectedCalendarDay = null; // Clear date on type change
            _selectedTime = null; // Clear time
            _availableSlots = [];
            _availableDates =
                []; // Clear current dates to prevent flashing old data
          });

          // Fetch new available dates for this specific type
          await _fetchPsychologistAvailability(label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? primary : surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? primary : rule, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : inkMuted, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : inkMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule),
      ),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 90)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedCalendarDay, day),
        enabledDayPredicate: (day) => _isDayAvailable(day),
        calendarFormat: CalendarFormat.month,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedCalendarDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _fetchTimeSlots(DateFormat('yyyy-MM-dd').format(selectedDay));
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    if (_isFetchingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rule),
        ),
        child: Column(
          children: [
            const Icon(Icons.info_outline, color: medium),
            const SizedBox(height: 8),
            Text(
              "No $_appointmentType slots available on this day.",
              style: const TextStyle(color: inkMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _availableSlots.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () => setState(() => _selectedTime = time),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primary : surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? primary : rule),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: isSelected ? Colors.white : inkDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: deep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                "Request Booking",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
