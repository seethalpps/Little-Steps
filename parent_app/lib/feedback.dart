import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> _feedbacks = [];
  bool _isLoading = false;
  bool _isFetching = true;
  String? _editingId; // Tracks if we are currently editing an existing record

  final Color primaryPurple = const Color(0xFF673AB7);

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  // --- 1. Fetch Feedback from Supabase ---
  Future<void> _fetchFeedback() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_feedback')
          .select()
          .eq('parent_id', user.id)
          .order('feedback_date', ascending: false);

      setState(() {
        _feedbacks = response;
        _isFetching = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isFetching = false);
    }
  }

  // --- 2. Submit or Update Feedback ---
  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your feedback")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      final data = {
        'parent_id': user?.id,
        'feedback_content': _feedbackController.text.trim(),
        'feedback_date': DateTime.now().toIso8601String(),
      };

      if (_editingId == null) {
        // Insert new record
        await supabase.from('tbl_feedback').insert({
          ...data,
          'feedback_id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      } else {
        // Update existing record
        await supabase
            .from('tbl_feedback')
            .update(data)
            .eq('feedback_id', _editingId!);
      }

      _feedbackController.clear();
      setState(() => _editingId = null);
      _fetchFeedback(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingId == null ? "Feedback submitted!" : "Feedback updated!",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. Delete Feedback ---
  Future<void> _deleteFeedback(String id) async {
    try {
      await supabase.from('tbl_feedback').delete().eq('feedback_id', id);
      _fetchFeedback(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Feedback deleted"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  // --- 4. Prepare Form for Editing ---
  void _prepareEdit(Map<String, dynamic> feedback) {
    setState(() {
      _editingId = feedback['feedback_id'].toString();
      _feedbackController.text = feedback['feedback_content'];
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
          "Feedback",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Input Form Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const Text(
                  "How was your experience?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Write your feedback here...",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitFeedback,
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
                            _editingId == null
                                ? "Submit Feedback"
                                : "Update Feedback",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (_editingId != null)
                  TextButton(
                    onPressed: () {
                      _feedbackController.clear();
                      setState(() => _editingId = null);
                    },
                    child: const Text(
                      "Cancel Edit",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Display History List
          Expanded(
            child: _isFetching
                ? Center(child: CircularProgressIndicator(color: primaryPurple))
                : _feedbacks.isEmpty
                ? const Center(child: Text("No feedback history found."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _feedbacks.length,
                    itemBuilder: (context, index) {
                      final item = _feedbacks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Text(
                            item['feedback_content'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(DateTime.parse(item['feedback_date'])),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
                                onPressed: () => _deleteFeedback(
                                  item['feedback_id'].toString(),
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
}
