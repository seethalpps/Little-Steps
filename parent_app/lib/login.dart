import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:parent_app/google.dart';
import 'package:parent_app/signup.dart';
import 'package:parent_app/main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _showPassword = false;

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }
    setState(() => isLoading = true);
    try {
      await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => google()),
        );
      }
    } catch (e) {
      if (mounted)
        _showSnackBar("Login failed: ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // ── Decorative blobs ───────────────────────────────────────
                  _buildTopDecoration(),
                  const SizedBox(height: 32),

                  // ── Header ─────────────────────────────────────────────────
                  _buildHeader(),
                  const SizedBox(height: 36),

                  // ── Form card ──────────────────────────────────────────────
                  _buildFormCard(),
                  const SizedBox(height: 24),

                  // ── Login button ───────────────────────────────────────────
                  _buildLoginButton(),
                  const SizedBox(height: 28),

                  // ── Sign up link ───────────────────────────────────────────
                  _buildSignUpRow(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TOP DECORATION ──────────────────────────────────────────────────────────

  Widget _buildTopDecoration() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background blobs
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: soft.withOpacity(0.55),
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: medium.withOpacity(0.2),
            ),
          ),
          // Logo / icon center
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [medium, primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/logo.png",
                width: 46,
                height: 46,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.child_care_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome back,",
          style: TextStyle(
            fontSize: 14,
            color: inkMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Log in to continue",
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: inkDark,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primary, medium]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─── FORM CARD ───────────────────────────────────────────────────────────────

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Email Address"),
          _buildTextField(
            controller: emailController,
            hint: "Enter your email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _fieldLabel("Password"),
          _buildPasswordField(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                // TODO: hook up forgot password
              },
              child: const Text(
                "Forgot password?",
                style: TextStyle(
                  fontSize: 12.5,
                  color: primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: inkMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        fillColor: background,
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

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: !_showPassword,
      style: const TextStyle(
        fontSize: 14.5,
        color: inkDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: "Enter your password",
        hintStyle: TextStyle(
          color: inkMuted.withOpacity(0.5),
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.lock_outline_rounded, color: medium, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => setState(() => _showPassword = !_showPassword),
            child: Icon(
              _showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: inkMuted,
              size: 18,
            ),
          ),
        ),
        filled: true,
        fillColor: background,
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

  // ─── LOGIN BUTTON ────────────────────────────────────────────────────────────

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: isLoading ? null : signIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [primary.withOpacity(0.5), medium.withOpacity(0.5)]
                : [deep, primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: isLoading
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
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Log In",
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

  // ─── SIGN UP ROW ─────────────────────────────────────────────────────────────

  Widget _buildSignUpRow() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Don't have an account? ",
            style: TextStyle(
              color: inkMuted,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Signup()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
