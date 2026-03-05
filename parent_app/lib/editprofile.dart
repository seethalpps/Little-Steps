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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? _newImageFile;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _isUpdating = false;

  final Color primaryPurple = const Color(0xFF673AB7);
  final Color surfaceColor = const Color(0xFFF8F9FE);

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
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tbl_parent')
          .select()
          .eq('parent_id', user.id)
          .single();

      setState(() {
        _nameController.text = data['parent_name'] ?? '';
        _emailController.text = data['parent_email'] ?? '';
        _contactController.text = data['parent_contact'] ?? '';
        _addressController.text = data['parent_address'] ?? '';
        _currentImageUrl = data['parent_photo'];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _newImageFile = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar("Name cannot be empty", Colors.redAccent);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      String? finalPhotoUrl = _currentImageUrl;

      if (_newImageFile != null) {
        final String fileName = 'profile_$userId.jpg';
        final String path = 'profiles/$fileName';

        await supabase.storage
            .from('parent')
            .upload(
              path,
              _newImageFile!,
              fileOptions: const FileOptions(upsert: true),
            );

        finalPhotoUrl = supabase.storage.from('parent').getPublicUrl(path);
      }

      await supabase
          .from('tbl_parent')
          .update({
            'parent_name': _nameController.text.trim(),
            'parent_email': _emailController.text.trim(),
            'parent_contact': _contactController.text.trim(),
            'parent_address': _addressController.text.trim(),
            'parent_photo': finalPhotoUrl,
          })
          .eq('parent_id', userId);

      if (mounted) {
        _showSnackBar("Profile successfully updated", primaryPurple);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Update failed: $e", Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: surfaceColor,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- Avatar Section ---
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 65,
                              backgroundColor: Colors.white,
                              backgroundImage: _newImageFile != null
                                  ? FileImage(_newImageFile!)
                                  : (_currentImageUrl != null &&
                                                _currentImageUrl!.isNotEmpty
                                            ? NetworkImage(_currentImageUrl!)
                                            : null)
                                        as ImageProvider?,
                              child:
                                  (_newImageFile == null &&
                                      (_currentImageUrl == null ||
                                          _currentImageUrl!.isEmpty))
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 65,
                                      color: Colors.grey[300],
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: primaryPurple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Form Section ---
                  _buildEditField(
                    _nameController,
                    "Full Name",
                    Icons.person_rounded,
                  ),
                  _buildEditField(
                    _emailController,
                    "Email Address",
                    Icons.email_rounded,
                    type: TextInputType.emailAddress,
                  ),
                  _buildEditField(
                    _contactController,
                    "Contact Number",
                    Icons.phone_iphone_rounded,
                    type: TextInputType.phone,
                  ),
                  _buildEditField(
                    _addressController,
                    "Residential Address",
                    Icons.location_on_rounded,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 40),

                  // --- Save Button ---
                  Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Update Profile",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),
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
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: type,
            maxLines: maxLines,
            style: const TextStyle(fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryPurple, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: primaryPurple.withOpacity(0.5)),
              ),
              hintText: "Enter your $label",
              hintStyle: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
