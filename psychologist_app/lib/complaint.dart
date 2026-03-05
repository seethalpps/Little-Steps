import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> _complaints = [];
  bool _isLoading = false;
  bool _isFetching = true;
  String? _editingId;

  final Color primaryPurple = const Color(0xFF673AB7);

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_complaint')
          .select()
          .eq('psychologist_id', user.id)
          .order('complaint_date', ascending: false);

      debugPrint("Fetched Complaints: $response");

      setState(() {
        _complaints = response;
        _isFetching = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  // --- Submit or Update Complaint ---
  Future<void> _submitComplaint() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      final data = {
        'complaint_title': _titleController.text.trim(),
        'complaint_content': _contentController.text.trim(),
        'psychologist_id': user?.id,
        'complaint_date': DateTime.now().toIso8601String(),
      };

      if (_editingId == null) {
        // FIXED: Generating unique ID to prevent PostgrestException (code 23502)
        await supabase.from('tbl_complaint').insert({
          ...data,
          'complaint_id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      } else {
        await supabase
            .from('tbl_complaint')
            .update(data)
            .eq('complaint_id', _editingId!);
      }

      _clearForm();
      await _fetchComplaints(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId == null ? "Complaint Submitted" : "Complaint Updated",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Delete Complaint ---
  Future<void> _deleteComplaint(String id) async {
    try {
      await supabase.from('tbl_complaint').delete().eq('complaint_id', id);
      await _fetchComplaints();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complaint deleted"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  void _clearForm() {
    _titleController.clear();
    _contentController.clear();
    setState(() => _editingId = null);
  }

  void _prepareEdit(Map<String, dynamic> complaint) {
    setState(() {
      _editingId = complaint['complaint_id'].toString();
      _titleController.text = complaint['complaint_title'];
      _contentController.text = complaint['complaint_content'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: const Text(
          "My Complaints",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Title",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: _buildInputDecoration("Enter complaint title"),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Content",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: _buildInputDecoration("Describe your issue"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _editingId == null ? "Submit" : "Update",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                if (_editingId != null)
                  Center(
                    child: TextButton(
                      onPressed: _clearForm,
                      child: const Text("Cancel Edit"),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: _isFetching
                ? Center(child: CircularProgressIndicator(color: primaryPurple))
                : _complaints.isEmpty
                ? const Center(child: Text("No history found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final item = _complaints[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            item['complaint_title'] ?? "No Title",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(item['complaint_content'] ?? ""),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => _prepareEdit(item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteComplaint(
                                  item['complaint_id'].toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[50],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
