import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'myprofile.dart';
import 'myappointments.dart';
import 'activity.dart';
import 'notificationpage.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  String parentName = "Parent";
  List<Map<String, dynamic>> upcomingAppointments = [];
  bool _isLoading = true;
  int unreadNotificationsCount = 0;

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

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fetchInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchParentName(),
        fetchAppointments(),
        fetchUnreadCount(),
      ]);
    } catch (e) {
      debugPrint("Initialization Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward(from: 0);
      }
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final countResponse = await supabase
          .from('tbl_notification')
          .select('id')
          .eq('parent_id', user.id)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          unreadNotificationsCount = (countResponse as List).length;
        });
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  Future<void> _fetchParentName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tbl_parent')
            .select('parent_name')
            .eq('parent_id', user.id)
            .maybeSingle();

        if (mounted && data != null) {
          setState(() {
            parentName = data['parent_name']?.split(' ')[0] ?? "Parent";
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching name: $e");
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final List<dynamic> data = await supabase
          .from('tbl_appointment')
          .select(
            '*, psychologist:tbl_psychologist(psychologist_name, psychologist_photo, psychologist_qualification)',
          )
          .eq('parent_id', user.id)
          .eq('appointment_status', 1)
          .order('appointment_date', ascending: true)
          .limit(3);
      if (mounted) {
        setState(
          () => upcomingAppointments = List<Map<String, dynamic>>.from(data),
        );
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning,";
    if (hour < 17) return "Good afternoon,";
    return "Good evening,";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primary, strokeWidth: 2),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _fetchInitialData,
                color: primary,
                backgroundColor: surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildSliverHero(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 28),
                            _buildProgressCard(),
                            const SizedBox(height: 36),
                            _buildSectionRule("CORE TOOLS"),
                            const SizedBox(height: 16),
                            _buildToolsGrid(),
                            const SizedBox(height: 36),
                            _buildSessionsHeader(),
                            const SizedBox(height: 16),
                            upcomingAppointments.isEmpty
                                ? _buildEmptyState("No confirmed appointments")
                                : Column(
                                    children: upcomingAppointments
                                        .map(_buildAppointmentCard)
                                        .toList(),
                                  ),
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

  Widget _buildSliverHero() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          var top = constraints.biggest.height;
          bool isCollapsed =
              top <= (MediaQuery.of(context).padding.top + kToolbarHeight + 20);

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: _buildHeroBackground(),
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 12,
            ),
            title: isCollapsed ? _buildCollapsedTitle() : null,
          );
        },
      ),
    );
  }

  Widget _buildHeroBackground() {
    return Container(
      color: background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: inkMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      parentName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: deep,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: soft.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationPage(),
                        ),
                      );
                      fetchUnreadCount();
                    },
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildCollapsedTitle() {
    return Text(
      parentName,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: deep,
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deep, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "WEEKLY PROGRESS",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "85",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  "%",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.85,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(soft),
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
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: rule, thickness: 1)),
      ],
    );
  }

  Widget _buildToolsGrid() {
    final tools = [
      _ToolItem(
        "Activities",
        Icons.extension_rounded,
        primary,
        soft,
        "Daily tracking",
        const Activity(),
      ),
      _ToolItem(
        "Community",
        Icons.forum_rounded,
        const Color(0xFF8B6BAA),
        const Color(0xFFE8D8F5),
        "Connect",
        null,
      ),
      _ToolItem(
        "Milestones",
        Icons.insights_rounded,
        const Color(0xFF6B8DB8),
        const Color(0xFFD8E8F4),
        "Progress",
        null,
      ),
      _ToolItem(
        "Resources",
        Icons.auto_stories_rounded,
        medium,
        const Color(0xFFEDE4F9),
        "Library",
        null,
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: tools.map(_buildToolTile).toList(),
    );
  }

  Widget _buildToolTile(_ToolItem tool) {
    return GestureDetector(
      onTap: () {
        if (tool.page != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => tool.page!),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: rule),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: tool.tintColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool.icon, color: tool.color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: inkDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle,
                    style: const TextStyle(
                      color: inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildSessionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "UPCOMING SESSIONS",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: inkMuted,
            letterSpacing: 2.5,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Myappointments()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "See all",
              style: TextStyle(
                fontSize: 11.5,
                color: primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final psy = appt['psychologist'];
    final date =
        DateTime.tryParse(appt['appointment_date'] ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
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
          CircleAvatar(
            radius: 26,
            backgroundColor: soft,
            backgroundImage: psy['psychologist_photo'] != null
                ? NetworkImage(psy['psychologist_photo'])
                : null,
            child: psy['psychologist_photo'] == null
                ? const Icon(Icons.person, color: primary)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  psy['psychologist_name'] ?? "Specialist",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: inkDark,
                  ),
                ),
                Text(
                  DateFormat('MMM d, yyyy').format(date),
                  style: const TextStyle(fontSize: 12, color: inkMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: soft.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              appt['appointment_time'] ?? "--:--",
              style: const TextStyle(
                color: primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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

// ── Missing Helper Class ──────────────────────────────────────────────────────
class _ToolItem {
  final String title;
  final IconData icon;
  final Color color;
  final Color tintColor;
  final String subtitle;
  final Widget? page;
  const _ToolItem(
    this.title,
    this.icon,
    this.color,
    this.tintColor,
    this.subtitle,
    this.page,
  );
}
