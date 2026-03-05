import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint>
    with SingleTickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> _complaints = [];
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
    _fetchComplaints();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final response = await supabase
          .from('tbl_complaint')
          .select()
          .eq('parent_id', user.id)
          .order('complaint_date', ascending: false);
      setState(() {
        _complaints = response;
        _isFetching = false;
      });
      _animController.forward(from: 0);
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _submitComplaint() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      final data = {
        'complaint_title': _titleController.text.trim(),
        'complaint_content': _contentController.text.trim(),
        'parent_id': user?.id,
        'complaint_date': DateTime.now().toIso8601String(),
      };

      if (_editingId == null) {
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
      await _fetchComplaints();

      if (mounted) {
        _showSnackBar(
          _editingId == null ? "Complaint submitted!" : "Complaint updated!",
        );
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteComplaint(String id) async {
    try {
      await supabase.from('tbl_complaint').delete().eq('complaint_id', id);
      await _fetchComplaints();
      if (mounted) _showSnackBar("Complaint deleted");
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
    // Scroll to top so user sees the form
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
          "My Complaints",
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

          // ── Divider rule ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: _buildSectionRule(
              _complaints.isEmpty ? "HISTORY" : "COMPLAINT HISTORY",
            ),
          ),
          const SizedBox(height: 14),

          // ── Complaint list ─────────────────────────────────────────────────
          Expanded(child: _buildComplaintList()),
        ],
      ),
    );
  }

  // ─── FORM SECTION ────────────────────────────────────────────────────────────

  Widget _buildFormSection() {
    final isEditing = _editingId != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _buildFormBanner(isEditing),
          const SizedBox(height: 20),

          // Form card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: rule),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel("Title"),
                _buildTextField(
                  controller: _titleController,
                  hint: "Enter complaint title",
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 16),
                _fieldLabel("Description"),
                _buildTextField(
                  controller: _contentController,
                  hint: "Describe your issue in detail...",
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action row
          Row(
            children: [
              if (isEditing) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: _clearForm,
                    child: Container(
                      height: 52,
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
                  onTap: _isLoading ? null : _submitComplaint,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 52,
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
                          blurRadius: 16,
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
                                  isEditing ? "Update" : "Submit",
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                  isEditing ? Icons.edit_note_rounded : Icons.feedback_outlined,
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
                      isEditing ? "Edit Complaint" : "New Complaint",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEditing
                          ? "Update your complaint details below."
                          : "Share your feedback or report an issue.",
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

  // ─── FIELD HELPERS ───────────────────────────────────────────────────────────

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
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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
          vertical: 14,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rule, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }

  // ─── COMPLAINT LIST ──────────────────────────────────────────────────────────

  Widget _buildComplaintList() {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: primary, strokeWidth: 2),
      );
    }

    if (_complaints.isEmpty) {
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
              child: const Icon(Icons.inbox_rounded, size: 36, color: primary),
            ),
            const SizedBox(height: 14),
            const Text(
              "No complaints yet",
              style: TextStyle(
                color: inkMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Submit one above to get started",
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
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          final item = _complaints[index] as Map<String, dynamic>;
          return _buildComplaintCard(item);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> item) {
    final bool isCurrentlyEditing =
        _editingId == item['complaint_id'].toString();

    String dateStr = "";
    try {
      final date = DateTime.parse(item['complaint_date'] ?? "");
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
                // Icon block
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCurrentlyEditing ? primary : soft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.feedback_outlined,
                    color: isCurrentlyEditing ? Colors.white : primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['complaint_title'] ?? "No Title",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: inkDark,
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                          _deleteComplaint(item['complaint_id'].toString()),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: rule, height: 1),
            const SizedBox(height: 10),
            Text(
              item['complaint_content'] ?? "",
              style: const TextStyle(
                fontSize: 13.5,
                color: inkMuted,
                height: 1.5,
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
