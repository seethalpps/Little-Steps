import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parent_app/changepass.dart';
import 'package:parent_app/complaint.dart';
import 'package:parent_app/feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parent_app/login.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings>
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

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
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
                  Icons.logout_rounded,
                  color: danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Log Out",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: inkDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Are you sure you want to log out of your account?",
                textAlign: TextAlign.center,
                style: TextStyle(color: inkMuted, fontSize: 13, height: 1.5),
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
                      onTap: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Log Out",
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
          "Settings",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Hero banner ──────────────────────────────────────────────
                _buildHeroBanner(),
                const SizedBox(height: 32),

                // ── Account group ────────────────────────────────────────────
                _buildSectionRule("ACCOUNT"),
                const SizedBox(height: 14),
                _buildGroup([
                  _SettingItem(
                    icon: Icons.lock_outline_rounded,
                    title: "Change Password",
                    subtitle: "Update your login password",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Changepass()),
                    ),
                  ),
                ]),
                const SizedBox(height: 28),

                // ── Support group ────────────────────────────────────────────
                _buildSectionRule("SUPPORT"),
                const SizedBox(height: 14),
                _buildGroup([
                  _SettingItem(
                    icon: Icons.report_problem_outlined,
                    title: "Complaints",
                    subtitle: "Report an issue or concern",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Complaint()),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.star_outline_rounded,
                    title: "Feedback",
                    subtitle: "Share your experience",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedbackPage()),
                    ),
                    isLast: true,
                  ),
                ]),
                const SizedBox(height: 32),

                // ── Logout button ────────────────────────────────────────────
                _buildLogoutButton(),
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
                    Icons.settings_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "App Settings",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Manage your account, preferences and support.",
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

  // ─── SETTINGS GROUP ──────────────────────────────────────────────────────────

  Widget _buildGroup(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
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
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildTile(item),
              if (i < items.length - 1)
                const Divider(
                  color: rule,
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile(_SettingItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: inkDark,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: const TextStyle(fontSize: 12, color: inkMuted),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LOGOUT BUTTON ───────────────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8EE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: danger.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: danger, size: 20),
            const SizedBox(width: 10),
            Text(
              "Log Out",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────────────────

class _SettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
}
