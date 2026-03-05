import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  String? _imageUrl;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  // --- PHOTO UPLOAD LOGIC ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    setState(() => _isUpdating = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final file = File(image.path);
      // Consistent filename based on User ID
      final fileName = 'profile_${user.id}.jpg';
      final path = 'profile_pics/$fileName';

      // 1. Upload to the 'User' bucket (upsert: true allows overwriting)
      await supabase.storage
          .from('User')
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      // 2. Get Public URL from the 'User' bucket
      final String publicUrl = supabase.storage.from('User').getPublicUrl(path);

      // 3. Update the database table with the new URL
      await supabase
          .from('tbl_psychologist')
          .update({'psychologist_photo': publicUrl})
          .eq('psychologist_id', user.id);

      // 4. Update local state with a "Cache Buster" timestamp
      // This forces the NetworkImage to refresh immediately
      setState(() {
        _imageUrl = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Photo updated successfully!")),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // Fetch current user data from Supabase
  Future<void> _loadCurrentData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tbl_psychologist')
          .select()
          .eq('psychologist_id', user.id)
          .single();

      setState(() {
        _nameController.text = data['psychologist_name'] ?? '';
        _emailController.text = data['psychologist_email'] ?? '';
        _contactController.text = data['psychologist_contact'] ?? '';
        _qualificationController.text =
            data['psychologist_qualification'] ?? '';
        _experienceController.text = data['psychologist_experience'] ?? '';

        // Initial load of the photo URL
        final rawUrl = data['psychologist_photo'];
        if (rawUrl != null && rawUrl.isNotEmpty) {
          _imageUrl = "$rawUrl?t=${DateTime.now().millisecondsSinceEpoch}";
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // Update text-based profile info
  Future<void> _updateProfile() async {
    setState(() => _isUpdating = true);
    try {
      final user = supabase.auth.currentUser;
      await supabase
          .from('tbl_psychologist')
          .update({
            'psychologist_name': _nameController.text.trim(),
            'psychologist_email': _emailController.text.trim(),
            'psychologist_contact': _contactController.text.trim(),
            'psychologist_qualification': _qualificationController.text.trim(),
            'psychologist_experience': _experienceController.text.trim(),
          })
          .eq('psychologist_id', user!.id);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF673AB7)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // --- PHOTO SECTION ---
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFFEDE7F6),
                          backgroundImage:
                              (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? NetworkImage(_imageUrl!)
                              : null,
                          child: (_imageUrl == null || _imageUrl!.isEmpty)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color(0xFF673AB7),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUpdating ? null : _pickAndUploadImage,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF673AB7),
                              child: _isUpdating
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  _buildEditField(
                    _nameController,
                    "Full Name",
                    Icons.person_outline,
                  ),
                  _buildEditField(
                    _emailController,
                    "Email",
                    Icons.email_outlined,
                    type: TextInputType.emailAddress,
                  ),
                  _buildEditField(
                    _contactController,
                    "Contact",
                    Icons.phone_iphone_outlined,
                    type: TextInputType.phone,
                  ),

                  const Divider(height: 40),

                  _buildEditField(
                    _qualificationController,
                    "Qualifications",
                    Icons.school_outlined,
                  ),
                  _buildEditField(
                    _experienceController,
                    "Years of Experience",
                    Icons.work_history_outlined,
                    type: TextInputType.number,
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF673AB7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SAVE CHANGES",
                              style: TextStyle(
                                color: Colors.white,
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

  Widget _buildEditField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF673AB7)),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2),
          ),
        ),
      ),
    );
  }
}
