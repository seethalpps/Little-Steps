import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Replace with your actual login file path
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Controllers
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phno = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phno.dispose();
    _address.dispose();
    _pass.dispose();
    super.dispose();
  }

  // Pick Image from Gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> insert() async {
    // 1. Basic Validation
    if (_email.text.isEmpty || _pass.text.isEmpty || _name.text.isEmpty) {
      _showSnackBar('Please fill in all required fields', Colors.red);
      return;
    }

    if (_imageFile == null) {
      _showSnackBar('Please select a profile photo', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Auth Sign Up (Creates user in Supabase Auth)
      final AuthResponse res = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      final String? userId = res.user?.id;

      if (userId != null) {
        // 3. Upload Image to "parent" bucket
        final String path = 'profiles/$userId.jpg';
        await Supabase.instance.client.storage
            .from('parent')
            .upload(path, _imageFile!);

        // 4. Get the Public URL of the uploaded image
        final String imageUrl = Supabase.instance.client.storage
            .from('parent')
            .getPublicUrl(path);

        // 5. Insert Profile Data into tbl_parent
        await Supabase.instance.client.from('tbl_parent').insert({
          'parent_id': userId,
          'parent_name': _name.text.trim(),
          'parent_email': _email.text.trim(),
          'parent_contact': _phno.text.trim(),
          'parent_address': _address.text.trim(),
          'parent_photo': imageUrl,
        });

        if (mounted) {
          _showSnackBar(
            'Registration Successful! Redirecting...',
            Colors.green,
          );

          // 6. Navigate to Login Page after a short delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            }
          });
        }
      }
    } on AuthApiException catch (error) {
      _showSnackBar(error.message, Colors.red);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Photo Picker UI
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF673AB7),
                      radius: 18,
                      child: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _inputField(_name, "Full Name", Icons.person_outline),
            _inputField(
              _email,
              "Email Address",
              Icons.email_outlined,
              type: TextInputType.emailAddress,
            ),
            _inputField(
              _phno,
              "Phone Number",
              Icons.phone_outlined,
              type: TextInputType.phone,
            ),
            _inputField(_address, "Home Address", Icons.map_outlined),
            _inputField(
              _pass,
              "Password",
              Icons.lock_outline,
              isPassword: true,
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : insert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF673AB7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "REGISTER",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: type,
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF673AB7)),
          labelText: label,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
      ),
    );
  }
}
