import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:psychologist_app/login.dart';
import 'package:psychologist_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phno = TextEditingController();
  final TextEditingController _qualification = TextEditingController();
  final TextEditingController _experience = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  // Storage for Photo
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  // Storage for Proof
  Uint8List? proofBytes;
  file_picker.PlatformFile? pickedProof;

  bool _isUploading = false;

  /// FILE PICKER LOGIC
  Future<void> handleFilePick({required bool isPhoto}) async {
    file_picker.FilePickerResult? result = await file_picker.FilePicker.platform
        .pickFiles(type: file_picker.FileType.image, withData: true);

    if (result == null) return;

    setState(() {
      if (isPhoto) {
        pickedImage = result.files.first;
        imageBytes = pickedImage!.bytes;
      } else {
        pickedProof = result.files.first;
        proofBytes = pickedProof!.bytes;
      }
    });
  }

  /// UNIVERSAL UPLOAD FUNCTION
  Future<String?> uploadToStorage(
    Uint8List bytes,
    String fileName,
    String folder,
  ) async {
    try {
      final extension = fileName.split('.').last;
      final path =
          "$folder/${DateTime.now().millisecondsSinceEpoch}.$extension";

      await supabase.storage
          .from('User')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$extension',
            ),
          );

      return supabase.storage.from('User').getPublicUrl(path);
    } catch (e) {
      debugPrint("❌ Upload error in $folder: $e");
      return null;
    }
  }

  Future<void> insert() async {
    if (imageBytes == null || proofBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both Photo and Proof")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 1. Auth Signup
      final AuthResponse res = await supabase.auth.signUp(
        email: _email.text,
        password: _pass.text,
      );

      final psychologistId = res.user!.id;

      // 2. Upload Files to Supabase Storage
      String? photoUrl = await uploadToStorage(
        imageBytes!,
        pickedImage!.name,
        "profile",
      );
      String? proofUrl = await uploadToStorage(
        proofBytes!,
        pickedProof!.name,
        "proofs",
      );

      // 3. Insert into Table
      await supabase.from('tbl_psychologist').insert({
        'psychologist_id': psychologistId,
        'psychologist_name': _name.text,
        'psychologist_email': _email.text,
        'psychologist_contact': _phno.text,
        'psychologist_qualification': _qualification.text,
        'psychologist_experience': _experience.text,
        'psychologist_photo': photoUrl, // Saving URL instead of text
        'psychologist_proof': proofUrl, // Saving URL instead of text
        'psychologist_password': _pass.text,
      });

      // 4. Cleanup
      _name.clear();
      _email.clear();
      _phno.clear();
      _pass.clear();
      _qualification.clear();
      _experience.clear();
      setState(() {
        imageBytes = null;
        proofBytes = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Signup Successful!")));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    } catch (e) {
      debugPrint("❌ Insertion error: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        leading: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Login()),
          ),
          child: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Form(
                child: Column(
                  children: [
                    const SizedBox(height: 19),

                    // --- PROFILE PHOTO SELECTION ---
                    GestureDetector(
                      onTap: () => handleFilePick(isPhoto: true),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: imageBytes != null
                            ? MemoryImage(imageBytes!)
                            : null,
                        child: imageBytes == null
                            ? const Icon(Icons.add_a_photo, size: 30)
                            : null,
                      ),
                    ),
                    const Text("Select Profile Photo"),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          label: Text(" Full Name"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          label: Text(" Email"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _phno,
                        decoration: const InputDecoration(
                          label: Text(" Phone Number"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _qualification,
                        decoration: const InputDecoration(
                          label: Text(" Qualification"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _experience,
                        decoration: const InputDecoration(
                          label: Text(" Experience"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    // --- PROOF SELECTION BUTTON ---
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18.0,
                        vertical: 8.0,
                      ),
                      child: InkWell(
                        onTap: () => handleFilePick(isPhoto: false),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.file_present),
                              const SizedBox(width: 10),
                              Text(
                                pickedProof != null
                                    ? "Proof: ${pickedProof!.name}"
                                    : "Upload Proof (ID/Certificate)",
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                          label: Text(" Password"),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    _isUploading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: insert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                61,
                                14,
                                86,
                                1,
                              ),
                              minimumSize: const Size(200, 50),
                            ),
                            child: const Text(
                              "Sign UP",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
