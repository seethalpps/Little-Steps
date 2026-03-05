import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parent_app/editprofile.dart';
import 'package:parent_app/childprofile.dart';
import 'package:parent_app/addchild.dart';
import 'package:parent_app/myappointments.dart';
import 'package:parent_app/settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Myprofile extends StatefulWidget {
  const Myprofile({super.key});

  @override
  State<Myprofile> createState() => _MyprofileState();
}

class _MyprofileState extends State<Myprofile>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? parentData;
  List<Map<String, dynamic>> upcomingAppointments = [];
  List<Map<String, dynamic>> childList = [];
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
  // ────────────────────────────────────────────────────────────────────────────

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    fetchInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([fetchData(), fetchAppointments(), fetchChild()]);
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward(from: 0);
    }
  }

  Future<void> fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final data = await supabase
          .from('tbl_parent')
          .select()
          .eq('parent_id', user.id)
          .single();
      setState(() => parentData = data);
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  Future<void> fetchChild() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final List<dynamic> data = await supabase
          .from('tbl_child')
          .select()
          .eq('parent_id', user.id)
          .order('child_name', ascending: true);
      setState(() => childList = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint("Error fetching children: $e");
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final List<dynamic> data = await supabase
          .from('tbl_appointment')
          .select(
            '*, psychologist:tbl_psychologist(psychologist_name, psychologist_photo)',
          )
          .eq('parent_id', user.id)
          .order('appointment_date', ascending: true);
      setState(
        () => upcomingAppointments = List<Map<String, dynamic>>.from(data),
      );
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            )
          : parentData == null
          ? const Center(child: Text("Profile not found"))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: fetchInitialData,
                color: primary,
                backgroundColor: surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),
                            _buildStatsRow(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              label: "YOUR CHILDREN",
                              actionLabel: "Add New",
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddChild(),
                                ),
                              ).then((_) => fetchChild()),
                            ),
                            const SizedBox(height: 14),
                            childList.isEmpty
                                ? _buildEmptyCard("No children added yet")
                                : _buildChildrenList(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(
                              label: "NEXT SESSION",
                              actionLabel: "View All",
                              onAction: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Myappointments(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildAppointmentCard(),
                            const SizedBox(height: 32),
                            _buildSectionHeader(label: "THERAPIST NOTE"),
                            const SizedBox(height: 14),
                            _buildNoteCard(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 290,
      pinned: true,
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: rule,
      elevation: 1,
      scrolledUnderElevation: 1,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: _iconBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: _iconBtn(
            icon: Icons.tune_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Settings()),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHero(),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: rule),
        ),
        child: Icon(icon, size: 15, color: primary),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: surface,
      child: Padding(
        padding: const EdgeInsets.only(top: 82, bottom: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [medium, primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.28),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(3),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: soft,
                    backgroundImage: parentData!['parent_photo'] != null
                        ? NetworkImage(parentData!['parent_photo'])
                        : null,
                    child: parentData!['parent_photo'] == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            size: 46,
                            color: primary,
                          )
                        : null,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Editprofile()),
                  ).then((_) => fetchData()),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [medium, primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: surface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              parentData!['parent_name'] ?? "Your Name",
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: inkDark,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                parentData!['parent_email'] ?? "No email",
                style: const TextStyle(
                  fontSize: 12.5,
                  color: primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statTile("${childList.length}", "Children", Icons.child_care_rounded),
        const SizedBox(width: 12),
        _statTile(
          "${upcomingAppointments.length}",
          "Sessions",
          Icons.event_available_rounded,
        ),
        const SizedBox(width: 12),
        _statTile("1", "Notes", Icons.sticky_note_2_outlined),
      ],
    );
  }

  Widget _statTile(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: rule),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primary),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                color: inkMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String label,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: inkMuted,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: rule, thickness: 1)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChildrenList() {
    final tiles = childList.map((child) {
      final name = child['child_name'] ?? 'C';
      final initials = name
          .toString()
          .trim()
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0] : '')
          .take(2)
          .join()
          .toUpperCase();
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => Childprofile(childData: child)),
        ).then((_) => fetchChild()),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: rule),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [medium, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: inkDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      child['child_gender'] ?? "Details not set",
                      style: const TextStyle(fontSize: 12.5, color: inkMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    tiles.add(
      GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddChild()),
        ).then((_) => fetchChild()),
        child: Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: rule, width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 18, color: primary),
              SizedBox(width: 6),
              Text(
                "Add a Child",
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Column(children: tiles);
  }

  Widget _buildAppointmentCard() {
    if (upcomingAppointments.isEmpty) {
      return _buildEmptyCard("No sessions scheduled yet");
    }
    final appt = upcomingAppointments.first;
    final psychName = appt['psychologist']?['psychologist_name'] ?? "Therapist";
    final date = appt['appointment_date'] ?? "TBD";
    final time = appt['appointment_time'] ?? "--:--";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Myappointments()),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [deep, primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.32),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 66,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _extractDay(date),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: surface,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _extractMonth(date),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    psychName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: surface,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDay(String date) {
    try {
      final p = date.split('-');
      if (p.length >= 3) return p[2];
    } catch (_) {}
    return date.length >= 2 ? date.substring(0, 2) : date;
  }

  String _extractMonth(String date) {
    const m = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    try {
      final p = date.split('-');
      if (p.length >= 2) {
        final i = int.tryParse(p[1]);
        if (i != null && i >= 1 && i <= 12) return m[i - 1];
      }
    } catch (_) {}
    return 'APR';
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.push_pin_rounded,
                  size: 14,
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Pinned Note",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: rule, thickness: 1),
          const SizedBox(height: 14),
          const Text(
            "Focus on motor skills development this week. Try the block-stacking activity mentioned by the therapist.",
            style: TextStyle(
              color: inkDark,
              height: 1.65,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: rule),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: inkMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
