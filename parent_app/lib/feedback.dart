import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _feedbackController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> _feedbacks = [];
  bool _isLoading = false;
  bool _isFetching = true;
  String? _editingId;

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchFeedback();
  }

  @override
  void dispose() {
    _animController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

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
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isFetching = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      _showSnackBar("Please enter your feedback", isError: true);
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
        await supabase.from('tbl_feedback').insert({
          ...data,
          'feedback_id': DateTime.now().millisecondsSinceEpoch.toString(),
        });
      } else {
        await supabase
            .from('tbl_feedback')
            .update(data)
            .eq('feedback_id', _editingId!);
      }

      final wasEditing = _editingId != null;
      _feedbackController.clear();
      setState(() => _editingId = null);
      await _fetchFeedback();
      if (mounted) {
        _showSnackBar(wasEditing ? "Feedback updated!" : "Feedback submitted!");
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFeedback(String id) async {
    try {
      await supabase.from('tbl_feedback').delete().eq('feedback_id', id);
      await _fetchFeedback();
      if (mounted) _showSnackBar("Feedback deleted");
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  void _prepareEdit(Map<String, dynamic> feedback) {
    setState(() {
      _editingId = feedback['feedback_id'].toString();
      _feedbackController.text = feedback['feedback_content'];
    });
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
        backgroundColor: isError ? danger : primary,
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
          "Feedback",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Form section ───────────────────────────────────────────────────
          _buildFormSection(),

          // ── List header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
            child: _buildSectionRule("FEEDBACK HISTORY"),
          ),

          // ── List ───────────────────────────────────────────────────────────
          Expanded(child: _buildFeedbackList()),
        ],
      ),
    );
  }

  // ─── FORM SECTION ────────────────────────────────────────────────────────────

  Widget _buildFormSection() {
    final isEditing = _editingId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          _buildFormBanner(isEditing),
          const SizedBox(height: 16),

          // Text area card
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rule),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: _feedbackController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 14.5,
                color: inkDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: isEditing
                    ? "Edit your feedback..."
                    : "Share your experience, suggestions, or concerns...",
                hintStyle: TextStyle(
                  color: inkMuted.withOpacity(0.5),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10, top: 14),
                  child: Icon(
                    isEditing
                        ? Icons.edit_note_rounded
                        : Icons.rate_review_outlined,
                    color: medium,
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Buttons row
          Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _feedbackController.clear();
                      setState(() => _editingId = null);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: rule),
                      ),
                      child: const Center(
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            color: inkMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: isEditing ? 2 : 1,
                child: GestureDetector(
                  onTap: _isLoading ? null : _submitFeedback,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isLoading
                            ? [
                                primary.withOpacity(0.5),
                                medium.withOpacity(0.5),
                              ]
                            : [deep, primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isEditing
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.send_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isEditing ? "Update" : "Submit Feedback",
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormBanner(bool isEditing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [deep, primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isEditing
                      ? Icons.edit_note_rounded
                      : Icons.star_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? "Edit Feedback" : "Share Your Experience",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEditing
                          ? "Update your feedback below."
                          : "Your feedback helps us improve.",
                      style: TextStyle(
                        fontSize: 12,
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

  // ─── FEEDBACK LIST ───────────────────────────────────────────────────────────

  Widget _buildFeedbackList() {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: primary, strokeWidth: 2),
      );
    }

    if (_feedbacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: soft.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                size: 36,
                color: primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "No feedback yet",
              style: TextStyle(
                color: inkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Submit your first feedback above",
              style: TextStyle(color: inkMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
        itemCount: _feedbacks.length,
        itemBuilder: (context, index) {
          final item = _feedbacks[index] as Map<String, dynamic>;
          return _buildFeedbackCard(item);
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final isCurrentlyEditing = _editingId == item['feedback_id'].toString();

    String dateStr = "";
    try {
      final date = DateTime.parse(item['feedback_date'] ?? "");
      dateStr = DateFormat('MMM d, yyyy').format(date);
    } catch (_) {}

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentlyEditing ? soft.withOpacity(0.3) : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentlyEditing ? primary : rule,
          width: isCurrentlyEditing ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(isCurrentlyEditing ? 0.1 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star icon block
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentlyEditing ? primary : soft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: isCurrentlyEditing ? Colors.white : primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (dateStr.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 10,
                              color: inkMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (isCurrentlyEditing)
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: soft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Editing",
                            style: TextStyle(
                              fontSize: 10,
                              color: primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(
                      icon: Icons.edit_outlined,
                      color: primary,
                      bgColor: soft,
                      onTap: () => _prepareEdit(item),
                    ),
                    const SizedBox(width: 8),
                    _actionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: danger,
                      bgColor: const Color(0xFFFDE8EE),
                      onTap: () =>
                          _deleteFeedback(item['feedback_id'].toString()),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: rule, height: 1),
            const SizedBox(height: 10),
            Text(
              item['feedback_content'] ?? "",
              style: const TextStyle(
                fontSize: 13.5,
                color: inkDark,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
