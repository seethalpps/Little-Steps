import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup>
    with SingleTickerProviderStateMixin {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phno = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  bool _showPassword = false;

  // ── Soft Lavender Palette ────────────────────────────────────────────────────
  static const Color deep        = Color(0xFF2D1B5E);
  static const Color primary     = Color(0xFF7B5EA7);
  static const Color medium      = Color(0xFFA688D4);
  static const Color soft        = Color(0xFFD4C4EE);
  static const Color background  = Color(0xFFF0EBF9);
  static const Color surface     = Color(0xFFFFFFFF);
  static const Color inkDark     = Color(0xFF2D1B5E);
  static const Color inkMuted    = Color(0xFF7B6A9A);
  static const Color rule        = Color(0xFFE6DDF5);
  // ────────────────────────────────────────────────────────────────────────────

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _name.dispose();
    _email.dispose();
    _phno.dispose();
    _address.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (image != null) setState(() => _imageFile = File(image.path));
  }

  Future<void> insert() async {
    if (_email.text.isEmpty || _pass.text.isEmpty || _name.text.isEmpty) {
      _showSnackBar('Please fill in all required fields', isError: true);
      return;
    }
    if (_imageFile == null) {
      _showSnackBar('Please select a profile photo', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final AuthResponse res =
          await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final String? userId = res.user?.id;

      if (userId != null) {
        final String path = 'profiles/$userId.jpg';
        await Supabase.instance.client.storage
            .from('parent')
            .upload(path, _imageFile!);

        final String imageUrl = Supabase.instance.client.storage
            .from('parent')
            .getPublicUrl(path);

        await Supabase.instance.client.from('tbl_parent').insert({
          'parent_id': userId,
          'parent_name': _name.text.trim(),
          'parent_email': _email.text.trim(),
          'parent_contact': _phno.text.trim(),
          'parent_address': _address.text.trim(),
          'parent_photo': imageUrl,
        });

        if (mounted) {
          _showSnackBar('Account created! Redirecting...');
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              );
            }
          });
        }
      }
    } on AuthApiException catch (error) {
      _showSnackBar(error.message, isError: true);
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? const Color(0xFF9B3A5A) : primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: primary, size: 15),
            ),
          ),
        ),
        title: Text("Create Account",
            style: GoogleFonts.playfairDisplay(
                fontSize: 20, fontWeight: FontWeight.bold, color: inkDark)),
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
                const SizedBox(height: 12),

                // ── Header ───────────────────────────────────────────────────
                _buildHeader(),
                const SizedBox(height: 28),

                // ── Avatar picker ────────────────────────────────────────────
                _buildAvatarPicker(),
                const SizedBox(height: 32),

                // ── Personal info ────────────────────────────────────────────
                _buildSectionRule("PERSONAL INFO"),
                const SizedBox(height: 16),
                _buildPersonalCard(),
                const SizedBox(height: 28),

                // ── Security ─────────────────────────────────────────────────
                _buildSectionRule("SECURITY"),
                const SizedBox(height: 16),
                _buildSecurityCard(),
                const SizedBox(height: 32),

                // ── Register button ──────────────────────────────────────────
                _buildRegisterButton(),
                const SizedBox(height: 20),

                // ── Login link ───────────────────────────────────────────────
                _buildLoginRow(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Hello there,",
            style: TextStyle(
                fontSize: 14,
                color: inkMuted,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text("Join us today",
            style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: inkDark,
                letterSpacing: -0.5,
                height: 1.1)),
        const SizedBox(height: 10),
        Container(
          width: 48, height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primary, medium]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─── AVATAR PICKER ───────────────────────────────────────────────────────────

  Widget _buildAvatarPicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
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
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: soft,
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person_outline_rounded,
                            size: 46, color: primary)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [medium, primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      shape: BoxShape.circle,
                      border: Border.all(color: surface, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _imageFile != null ? "Photo selected ✓" : "Tap to add profile photo",
            style: TextStyle(
                fontSize: 12.5,
                color: _imageFile != null ? primary : inkMuted,
                fontWeight: _imageFile != null
                    ? FontWeight.w700
                    : FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ─── SECTION RULE ────────────────────────────────────────────────────────────

  Widget _buildSectionRule(String label) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: inkMuted,
                letterSpacing: 2.5)),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: rule, thickness: 1)),
      ],
    );
  }

  // ─── PERSONAL CARD ───────────────────────────────────────────────────────────

  Widget _buildPersonalCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Full Name"),
          _buildTextField(
              controller: _name,
              hint: "Enter your full name",
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 18),

          _fieldLabel("Email Address"),
          _buildTextField(
              controller: _email,
              hint: "Enter your email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 18),

          _fieldLabel("Phone Number"),
          _buildTextField(
              controller: _phno,
              hint: "Enter your phone number",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 18),

          _fieldLabel("Home Address"),
          _buildTextField(
              controller: _address,
              hint: "Enter your address",
              icon: Icons.location_on_outlined,
              maxLines: 2),
        ],
      ),
    );
  }

  // ─── SECURITY CARD ───────────────────────────────────────────────────────────

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel("Password"),
          _buildPasswordField(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 12, color: inkMuted),
              const SizedBox(width: 5),
              Text("At least 6 characters",
                  style: TextStyle(
                      fontSize: 11,
                      color: inkMuted.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FIELD HELPERS ───────────────────────────────────────────────────────────

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: inkMuted,
              letterSpacing: 0.3)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
          fontSize: 14.5, color: inkDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: inkMuted.withOpacity(0.5),
            fontSize: 13.5,
            fontWeight: FontWeight.w400),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: medium, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: background,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
      controller: _pass,
      obscureText: !_showPassword,
      style: const TextStyle(
          fontSize: 14.5, color: inkDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: "Create a strong password",
        hintStyle: TextStyle(
            color: inkMuted.withOpacity(0.5),
            fontSize: 13.5,
            fontWeight: FontWeight.w400),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.lock_outline_rounded, color: medium, size: 18),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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

  // ─── REGISTER BUTTON ─────────────────────────────────────────────────────────

  Widget _buildRegisterButton() {
    return GestureDetector(
      onTap: _isLoading ? null : insert,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
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
                offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text("Create Account",
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2)),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── LOGIN ROW ───────────────────────────────────────────────────────────────

  Widget _buildLoginRow() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Already have an account? ",
              style: TextStyle(
                  color: inkMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500)),
          GestureDetector(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: soft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text("Sign in",
                  style: TextStyle(
                      color: primary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}