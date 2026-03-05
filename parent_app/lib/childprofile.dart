import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:parent_app/editchild.dart';
import 'package:parent_app/myprofile.dart';

class Childprofile extends StatefulWidget {
  final Map<String, dynamic> childData;
  const Childprofile({super.key, required this.childData});

  @override
  State<Childprofile> createState() => _ChildprofileState();
}

class _ChildprofileState extends State<Childprofile>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

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

  List<BarChartGroupData> barGroups = [];
  Map<int, String> activityLabels = {};
  Map<String, int> rawStats = {};
  List<Map<String, dynamic>> recentLogs = [];
  bool _isLoading = true;
  bool _showInHours = false;
  int _weekOffset = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchActivityData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivityData() async {
    setState(() => _isLoading = true);
    try {
      final childId = widget.childData['child_id'];
      final now = DateTime.now();
      final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = startOfThisWeek.add(Duration(days: _weekOffset * 7));
      final end = start.add(const Duration(days: 6));
      final startStr = start.toIso8601String().substring(0, 10);
      final endStr = end.toIso8601String().substring(0, 10);

      final data = await supabase
          .from('tbl_activity')
          .select('*')
          .eq('child_id', childId)
          .gte('log_date', startStr)
          .lte('log_date', endStr)
          .order('log_date', ascending: false);

      final logs = List<Map<String, dynamic>>.from(data);

      if (logs.isEmpty) {
        setState(() {
          recentLogs = [];
          barGroups = [];
          activityLabels = {};
          rawStats = {};
          _isLoading = false;
        });
        _animController.forward(from: 0);
        return;
      }

      Map<String, int> stats = {};
      for (var row in logs) {
        String cat = row['activity_category'] ?? "Other";
        int dur = int.tryParse(row['activity_duration'].toString()) ?? 0;
        stats[cat] = (stats[cat] ?? 0) + dur;
      }

      Map<int, String> tempLabels = {};
      int i = 0;
      stats.forEach((name, _) {
        tempLabels[i] = name;
        i++;
      });

      setState(() {
        rawStats = stats;
        activityLabels = tempLabels;
        recentLogs = logs;
        _isLoading = false;
      });
      _rebuildBarGroups();
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Data Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _rebuildBarGroups() {
    if (rawStats.isEmpty) {
      setState(() => barGroups = []);
      return;
    }
    double maxRaw = rawStats.values.reduce((a, b) => a > b ? a : b).toDouble();
    List<BarChartGroupData> tempGroups = [];
    int index = 0;
    rawStats.forEach((name, totalMinutes) {
      double displayVal = _showInHours
          ? totalMinutes / 60.0
          : totalMinutes.toDouble();
      double maxDisplay = _showInHours ? maxRaw / 60.0 : maxRaw;
      tempGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: displayVal,
              gradient: const LinearGradient(
                colors: [medium, primary],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 20,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxDisplay * 1.25,
                color: soft.withOpacity(0.3),
              ),
            ),
          ],
        ),
      );
      index++;
    });
    setState(() => barGroups = tempGroups);
  }

  Future<void> _deleteActivity(int logId) async {
    try {
      await supabase.from('tbl_activity').delete().eq('activity_id', logId);
      _fetchActivityData();
      if (mounted) {
        _showSnackBar("Activity deleted successfully");
      }
    } catch (e) {
      debugPrint("Delete Activity Error: $e");
    }
  }

  Future<void> _editActivity(Map<String, dynamic> log) async {
    final notesCtrl = TextEditingController(text: log['activity_notes']);
    final durationCtrl = TextEditingController(
      text: log['activity_duration'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Activity",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: inkDark,
                ),
              ),
              const SizedBox(height: 20),
              _dialogField(
                controller: durationCtrl,
                label: "Duration (min)",
                icon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              _dialogField(
                controller: notesCtrl,
                label: "Notes",
                icon: Icons.notes_rounded,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: rule),
                        ),
                        child: const Center(
                          child: Text(
                            "Cancel",
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
                      onTap: () async {
                        await supabase
                            .from('tbl_activity')
                            .update({
                              'activity_notes': notesCtrl.text,
                              'activity_duration':
                                  int.tryParse(durationCtrl.text) ?? 0,
                            })
                            .eq('activity_id', log['activity_id']);
                        if (mounted) Navigator.pop(context);
                        _fetchActivityData();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [deep, primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Update",
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

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: inkDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: inkMuted, fontSize: 13),
        prefixIcon: Icon(icon, color: medium, size: 18),
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _deleteChild() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Delete Profile",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: inkDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to delete this child profile? This action cannot be undone.",
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
                            "Cancel",
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
                            "Delete",
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

    if (confirm == true) {
      await supabase
          .from('tbl_child')
          .delete()
          .eq('child_id', widget.childData['child_id']);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Myprofile()),
          (route) => false,
        );
      }
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
        backgroundColor: isError ? danger : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _weekLabel() {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = startOfThisWeek.add(Duration(days: _weekOffset * 7));
    final end = start.add(const Duration(days: 6));
    String fmt(DateTime d) => "${d.day} ${_monthAbbr(d.month)}";
    if (_weekOffset == 0) return "This Week";
    if (_weekOffset == -1) return "Last Week";
    return "${fmt(start)} – ${fmt(end)}";
  }

  String _monthAbbr(int m) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[m];
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.childData['child_name'] ?? "Child";
    final initials = name
        .toString()
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(name, initials),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 28),
                          _buildSectionRule("ACTIVITY BREAKDOWN"),
                          const SizedBox(height: 16),
                          _buildActivityGraph(),
                          const SizedBox(height: 32),
                          _buildSectionRule("PROFILE DETAILS"),
                          const SizedBox(height: 16),
                          _buildDetailsCard(),
                          if (recentLogs.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionRule("RECENT HISTORY"),
                            const SizedBox(height: 16),
                            _buildRecentLogs(),
                          ],
                          const SizedBox(height: 32),
                          _buildActionButtons(),
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── SLIVER APP BAR ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(String name, String initials) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      scrolledUnderElevation: 1,
      shadowColor: rule,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: background,
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHero(name, initials),
      ),
    );
  }

  Widget _buildHero(String name, String initials) {
    return Container(
      color: surface,
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: soft.withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -60,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: soft.withOpacity(0.25),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 72, bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gradient avatar
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [medium, primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: inkDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.childData['child_gender'] ?? "Child",
                    style: const TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION RULE ────────────────────────────────────────────────────────────

  Widget _buildSectionRule(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: inkMuted,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: rule, thickness: 1)),
      ],
    );
  }

  // ─── ACTIVITY GRAPH ──────────────────────────────────────────────────────────

  Widget _buildActivityGraph() {
    double maxRaw = rawStats.isNotEmpty
        ? rawStats.values.reduce((a, b) => a > b ? a : b).toDouble()
        : (_showInHours ? 2.0 : 100.0);
    double chartMaxY = _showInHours
        ? ((maxRaw / 60.0) * 1.25).ceilToDouble()
        : (maxRaw * 1.25).ceilToDouble();
    if (chartMaxY == 0) chartMaxY = _showInHours ? 2 : 100;
    double interval = (chartMaxY / 5).ceilToDouble();
    if (interval < 1) interval = 1;

    return Container(
      height: 320,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                // Week navigator
                GestureDetector(
                  onTap: () {
                    setState(() => _weekOffset--);
                    _fetchActivityData();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rule),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _weekLabel(),
                  style: const TextStyle(
                    color: primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _weekOffset < 0
                      ? () {
                          setState(() => _weekOffset++);
                          _fetchActivityData();
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: _weekOffset < 0 ? background : rule,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rule),
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: _weekOffset < 0 ? primary : inkMuted,
                      size: 16,
                    ),
                  ),
                ),
                const Spacer(),
                // Unit toggle
                Container(
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: rule),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['min', 'hr'].map((unit) {
                      final active =
                          (_showInHours && unit == 'hr') ||
                          (!_showInHours && unit == 'min');
                      return GestureDetector(
                        onTap: () {
                          setState(() => _showInHours = unit == 'hr');
                          _rebuildBarGroups();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: active ? primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            unit,
                            style: TextStyle(
                              color: active ? Colors.white : inkMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 2),
            child: Text(
              "Time (${_showInHours ? 'hr' : 'min'})",
              style: const TextStyle(color: inkMuted, fontSize: 10),
            ),
          ),
          Expanded(
            child: barGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, size: 36, color: soft),
                        const SizedBox(height: 8),
                        const Text(
                          "No activities this week",
                          style: TextStyle(
                            color: inkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: chartMaxY,
                      barGroups: barGroups,
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          left: BorderSide(color: rule),
                          bottom: BorderSide(color: rule),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: interval,
                        getDrawingHorizontalLine: (val) =>
                            FlLine(color: background, strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: interval,
                            reservedSize: 36,
                            getTitlesWidget: (value, meta) => Text(
                              value == 0
                                  ? "0"
                                  : (_showInHours
                                        ? value.toStringAsFixed(1)
                                        : value.toInt().toString()),
                              style: const TextStyle(
                                fontSize: 9,
                                color: inkMuted,
                              ),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              String label =
                                  activityLabels[value.toInt()] ?? '';
                              if (label.length > 7)
                                label = "${label.substring(0, 5)}..";
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: inkMuted,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (group) => deep,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            String label = activityLabels[group.x] ?? '';
                            String val = _showInHours
                                ? "${rod.toY.toStringAsFixed(2)} hr"
                                : "${rod.toY.toInt()} min";
                            return BarTooltipItem(
                              '$label\n$val',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── DETAILS CARD ────────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailTile(
            Icons.wc_rounded,
            "Gender",
            widget.childData['child_gender'] ?? "N/A",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: rule, height: 1),
          ),
          _buildDetailTile(
            Icons.cake_outlined,
            "Date of Birth",
            widget.childData['child_dob'] ?? "N/A",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: rule, height: 1),
          ),
          _buildDetailTile(
            Icons.sticky_note_2_outlined,
            "Health Notes",
            widget.childData['child_notes'] ?? "No notes.",
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: inkMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: inkDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── RECENT LOGS ─────────────────────────────────────────────────────────────

  Widget _buildRecentLogs() {
    final activityIcons = {
      "Reading": Icons.menu_book_rounded,
      "Drawing": Icons.palette_rounded,
      "Outdoor Play": Icons.wb_sunny_rounded,
      "Puzzles": Icons.extension_rounded,
      "Music": Icons.music_note_rounded,
      "Exercise": Icons.directions_run_rounded,
    };

    return Column(
      children: recentLogs.take(5).map((log) {
        final cat = log['activity_category'] ?? "Activity";
        final icon = activityIcons[cat] ?? Icons.bolt_rounded;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: rule),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, color: primary, size: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: inkDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log['activity_notes']?.isNotEmpty == true
                          ? log['activity_notes']
                          : "No notes",
                      style: const TextStyle(fontSize: 12, color: inkMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${log['activity_duration']}m",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: inkMuted,
                  size: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                color: surface,
                onSelected: (value) {
                  if (value == 'edit')
                    _editActivity(log);
                  else if (value == 'delete')
                    _deleteActivity(log['activity_id']);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: primary),
                        const SizedBox(width: 10),
                        const Text(
                          "Edit",
                          style: TextStyle(
                            color: inkDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: danger,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Delete",
                          style: TextStyle(
                            color: danger,
                            fontWeight: FontWeight.w600,
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
      }).toList(),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Edit button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Editchild(childData: widget.childData),
            ),
          ),
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [deep, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  "Edit Profile",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Delete button
        GestureDetector(
          onTap: _deleteChild,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: danger.withOpacity(0.25), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: danger,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  "Delete Profile",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: danger,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
