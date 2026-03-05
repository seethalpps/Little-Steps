import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Activity extends StatefulWidget {
  const Activity({super.key});

  @override
  State<Activity> createState() => _ActivityState();
}

class _ActivityState extends State<Activity>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> children = [];
  String? selectedChildId;
  String? selectedActivityCategory;
  String selectedUnit = 'min';

  final TextEditingController _activityDurationController =
      TextEditingController();
  final TextEditingController _activityNotesController =
      TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

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
  // ────────────────────────────────────────────────────────────────────────────

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> activityTypes = [
    {
      "name": "Reading",
      "icon": Icons.menu_book_rounded,
      "color": const Color(0xFF4A90D9),
      "tint": const Color(0xFFDEEEFA),
    },
    {
      "name": "Drawing",
      "icon": Icons.palette_rounded,
      "color": const Color(0xFFE07B39),
      "tint": const Color(0xFFFAEBDE),
    },
    {
      "name": "Outdoor Play",
      "icon": Icons.wb_sunny_rounded,
      "color": const Color(0xFF5B9E6A),
      "tint": const Color(0xFFDEF0E3),
    },
    {
      "name": "Puzzles",
      "icon": Icons.extension_rounded,
      "color": primary,
      "tint": soft,
    },
    {
      "name": "Music",
      "icon": Icons.music_note_rounded,
      "color": const Color(0xFFB05C9E),
      "tint": const Color(0xFFF5E0F2),
    },
    {
      "name": "Exercise",
      "icon": Icons.directions_run_rounded,
      "color": const Color(0xFF3A9E9E),
      "tint": const Color(0xFFDEF2F2),
    },
  ];

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
    fetchChildren();
  }

  @override
  void dispose() {
    _animController.dispose();
    _activityDurationController.dispose();
    _activityNotesController.dispose();
    super.dispose();
  }

  Future<void> fetchChildren() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }
      final data = await supabase
          .from('tbl_child')
          .select('child_id, child_name')
          .eq('parent_id', user.id);
      setState(() {
        children = List<Map<String, dynamic>>.from(data);
        if (children.isNotEmpty) {
          selectedChildId = children[0]['child_id'].toString();
        }
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      debugPrint("Error fetching children: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (selectedChildId == null ||
        selectedActivityCategory == null ||
        _activityDurationController.text.isEmpty) {
      _showSnackBar("Please fill in all required fields", isError: true);
      return;
    }
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showSnackBar("User not authenticated", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      int? durationValue = int.tryParse(_activityDurationController.text);
      if (durationValue == null) {
        _showSnackBar(
          "Please enter a valid number for duration",
          isError: true,
        );
        return;
      }
      if (selectedUnit == 'hrs') durationValue = durationValue * 60;

      await supabase.from('tbl_activity').insert({
        'child_id': selectedChildId,
        'activity_category': selectedActivityCategory,
        'activity_duration': durationValue,
        'activity_notes': _activityNotesController.text.trim(),
      });

      if (mounted) {
        _showSnackBar("Activity saved successfully!");
        Navigator.pop(context);
      }
    } on PostgrestException catch (error) {
      _showSnackBar("Database Error: ${error.message}", isError: true);
      debugPrint("Postgres Error: ${error.details}");
    } catch (e) {
      _showSnackBar("An unexpected error occurred", isError: true);
      debugPrint("Error saving activity: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? const Color(0xFF9B3A5A) : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          "Log Activity",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            )
          : FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // ── Hero banner ──────────────────────────────────────
                      _buildHeroBanner(),
                      const SizedBox(height: 32),

                      // ── Child selector ───────────────────────────────────
                      _buildSectionRule("SELECT CHILD"),
                      const SizedBox(height: 14),
                      _buildChildSelector(),
                      const SizedBox(height: 32),

                      // ── Duration ─────────────────────────────────────────
                      _buildSectionRule("DURATION"),
                      const SizedBox(height: 14),
                      _buildDurationRow(),
                      const SizedBox(height: 32),

                      // ── Activity type ────────────────────────────────────
                      _buildSectionRule("ACTIVITY TYPE"),
                      const SizedBox(height: 14),
                      _buildActivityGrid(),
                      const SizedBox(height: 32),

                      // ── Notes ────────────────────────────────────────────
                      _buildSectionRule("NOTES"),
                      const SizedBox(height: 14),
                      _buildNotesField(),
                      const SizedBox(height: 36),

                      // ── Save button ──────────────────────────────────────
                      _buildSaveButton(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── HERO BANNER ─────────────────────────────────────────────────────────────

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deep, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Daily Activity Log",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Track your child's activities & progress",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withOpacity(0.65),
                        height: 1.4,
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

  // ─── CHILD SELECTOR ──────────────────────────────────────────────────────────

  Widget _buildChildSelector() {
    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rule),
        ),
        child: const Center(
          child: Text(
            "No children added yet",
            style: TextStyle(color: inkMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedChildId,
          isExpanded: true,
          dropdownColor: surface,
          icon: const Icon(Icons.expand_more_rounded, color: primary),
          style: const TextStyle(
            fontSize: 14.5,
            color: inkDark,
            fontWeight: FontWeight.w600,
          ),
          hint: const Text(
            "Select a child",
            style: TextStyle(color: inkMuted, fontSize: 14),
          ),
          items: children.map((c) {
            final name = c['child_name'] ?? '';
            final initials = name
                .toString()
                .trim()
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase();
            return DropdownMenuItem(
              value: c['child_id'].toString(),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [medium, primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: surface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(name),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => selectedChildId = v),
        ),
      ),
    );
  }

  // ─── DURATION ROW ────────────────────────────────────────────────────────────

  Widget _buildDurationRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildTextField(
            hint: "e.g. 30",
            controller: _activityDurationController,
            icon: Icons.timer_outlined,
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 12),
        _buildUnitToggle(),
      ],
    );
  }

  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14.5,
        color: inkDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: inkMuted.withOpacity(0.5),
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: medium, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: rule, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rule),
      ),
      child: Row(
        children: ['min', 'hrs'].map((unit) {
          final isSelected = selectedUnit == unit;
          return GestureDetector(
            onTap: () => setState(() => selectedUnit = unit),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unit,
                style: TextStyle(
                  color: isSelected ? Colors.white : inkMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── ACTIVITY GRID ───────────────────────────────────────────────────────────

  Widget _buildActivityGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: activityTypes.map((act) => _buildActivityTile(act)).toList(),
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> act) {
    final isSelected = selectedActivityCategory == act['name'];
    final Color tileColor = act['color'] as Color;
    final Color tileTint = act['tint'] as Color;

    return GestureDetector(
      onTap: () => setState(() => selectedActivityCategory = act['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primary : surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? primary : rule,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? primary.withOpacity(0.22)
                  : primary.withOpacity(0.04),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.18) : tileTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Icon(
                  act['icon'] as IconData,
                  color: isSelected ? Colors.white : tileColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                act['name'] as String,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : inkDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NOTES FIELD ─────────────────────────────────────────────────────────────

  Widget _buildNotesField() {
    return _buildTextField(
      hint: "Any observations or comments...",
      controller: _activityNotesController,
      icon: Icons.notes_rounded,
      maxLines: 3,
    );
  }

  // ─── SAVE BUTTON ─────────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _isSaving ? null : _handleSave,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSaving
                ? [primary.withOpacity(0.5), medium.withOpacity(0.5)]
                : [deep, primary],
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
        child: Center(
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Save Activity",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
