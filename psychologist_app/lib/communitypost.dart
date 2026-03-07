import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Communitypost extends StatefulWidget {
  const Communitypost({super.key});

  @override
  State<Communitypost> createState() => _CommunitypostState();
}

class _CommunitypostState extends State<Communitypost>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  bool isShowingMyPosts = false;
  String searchQuery = "";
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int _selectedCommentStatus = 2;
  XFile? _tempPickedFile;
  bool _isUploading = false;

  Map<int, bool> userLikes = {};
  Map<int, int> likeCounts = {};

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadInitialLikeData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLikeData() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final myLikes = await supabase
          .from('tbl_like')
          .select('post_id')
          .eq('psychologist_id', userId);
      final allLikes = await supabase.from('tbl_like').select('post_id');

      Map<int, bool> tempUserLikes = {};
      Map<int, int> tempLikeCounts = {};
      for (var row in myLikes) {
        tempUserLikes[row['post_id']] = true;
      }
      for (var row in allLikes) {
        int pid = row['post_id'];
        tempLikeCounts[pid] = (tempLikeCounts[pid] ?? 0) + 1;
      }
      setState(() {
        userLikes = tempUserLikes;
        likeCounts = tempLikeCounts;
      });
    } catch (e) {
      debugPrint("Init Load Error: $e");
    }
  }

  Future<void> _likePost(int postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    setState(() {
      if (userLikes[postId] == true) {
        userLikes[postId] = false;
        likeCounts[postId] = (likeCounts[postId] ?? 1) - 1;
      } else {
        userLikes[postId] = true;
        likeCounts[postId] = (likeCounts[postId] ?? 0) + 1;
      }
    });
    try {
      if (userLikes[postId] == false) {
        await supabase
            .from('tbl_like')
            .delete()
            .eq('post_id', postId)
            .eq('psychologist_id', userId);
      } else {
        await supabase.from('tbl_like').insert({
          'post_id': postId,
          'psychologist_id': userId,
        });
      }
    } catch (e) {
      debugPrint("Like Sync Error: $e");
      _loadInitialLikeData();
    }
  }

  Future<void> _submitPost(StateSetter setModalState) async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Please enter a title", isError: true);
      return;
    }
    setState(() => _isUploading = true);
    setModalState(() => _isUploading = true);

    String? fileUrl;
    try {
      if (_tempPickedFile != null) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${_tempPickedFile!.name}';
        final path = 'uploads/$fileName';
        await supabase.storage
            .from('post_files')
            .upload(path, File(_tempPickedFile!.path));
        fileUrl = supabase.storage.from('post_files').getPublicUrl(path);
      }

      await supabase.from('tbl_post').insert({
        'post_title': _titleController.text.trim(),
        'post_details': _descriptionController.text.trim(),
        'post_file': fileUrl,
        'comment_status': _selectedCommentStatus,
        'psychologist_id': supabase.auth.currentUser?.id,
        'parent_id': null, // Explicitly null for psychologist post
      });

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Post shared successfully!");
      }
    } catch (e) {
      debugPrint("Submission Error: $e");
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
        setModalState(() => _isUploading = false);
      }
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

  void _showAddPostSheet() {
    _tempPickedFile = null;
    _selectedCommentStatus = 2;
    _titleController.clear();
    _descriptionController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 22,
            right: 22,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: rule,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Create Post",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: inkDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sheetFieldLabel("Title"),
                _sheetTextField(
                  controller: _titleController,
                  hint: "What's on your mind?",
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 16),
                _sheetFieldLabel("Description"),
                _sheetTextField(
                  controller: _descriptionController,
                  hint: "Share more details...",
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _sheetFieldLabel("Who can comment?"),
                Row(
                  children: [
                    _commentOption(
                      ctx,
                      setModalState,
                      2,
                      "Everyone",
                      Icons.public_rounded,
                    ),
                    const SizedBox(width: 10),
                    _commentOption(
                      ctx,
                      setModalState,
                      1,
                      "Psychologists",
                      Icons.psychology_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (img != null) setModalState(() => _tempPickedFile = img);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _tempPickedFile != null ? primary : rule,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _tempPickedFile != null
                              ? Icons.check_circle_outline_rounded
                              : Icons.image_outlined,
                          color: _tempPickedFile != null ? primary : medium,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _tempPickedFile != null
                                ? _tempPickedFile!.name
                                : "Attach image (optional)",
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _tempPickedFile != null
                                  ? inkDark
                                  : inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _isUploading ? null : () => _submitPost(setModalState),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isUploading
                            ? [
                                primary.withOpacity(0.5),
                                medium.withOpacity(0.5),
                              ]
                            : [deep, primary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _isUploading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              "Share Post",
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (Comment Option, Sheet Field Label, Sheet Text Field widgets remain same as your original) ...
  Widget _commentOption(
    BuildContext ctx,
    StateSetter setModalState,
    int value,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedCommentStatus == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setModalState(() => _selectedCommentStatus = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? primary : background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? primary : rule),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : inkMuted),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: inkMuted,
      ),
    ),
  );

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: medium, size: 18),
        filled: true,
        fillColor: background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: rule),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;
    final postStream = supabase
        .from('tbl_post')
        .stream(primaryKey: ['post_id'])
        .order('post_id', ascending: false);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        centerTitle: true,
        title: Text(
          "Community",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddPostSheet,
            icon: const Icon(Icons.add_circle, color: primary, size: 28),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildTabSwitcher(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: postStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final posts = snapshot.data ?? [];
                  final filtered = posts.where((p) {
                    final matchesTab = isShowingMyPosts
                        ? p['psychologist_id'] == userId
                        : true;
                    return matchesTab &&
                        (p['post_title'] as String).toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        _buildPostCard(filtered[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => searchQuery = v),
      decoration: InputDecoration(
        hintText: "Search posts...",
        prefixIcon: const Icon(Icons.search, color: medium),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: rule),
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Row(
      children: [
        _tabOption(
          "My Posts",
          isShowingMyPosts,
          () => setState(() => isShowingMyPosts = true),
        ),
        const SizedBox(width: 8),
        _tabOption(
          "All Posts",
          !isShowingMyPosts,
          () => setState(() => isShowingMyPosts = false),
        ),
      ],
    );
  }

  Widget _tabOption(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primary : surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: rule),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : inkMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── UPDATED POST CARD ───────────────────────────────────────────────────────────────

  Widget _buildPostCard(Map<String, dynamic> post) {
    final int pid = post['post_id'];
    final bool isLiked = userLikes[pid] ?? false;
    final int count = likeCounts[pid] ?? 0;

    // Check if the author is a Psychologist
    final bool isPsychologistPost = post['psychologist_id'] != null;
    final bool isOwnPost =
        post['psychologist_id'] == supabase.auth.currentUser?.id;

    // Colors: Purple for Psychologists, White for Parents
    final Color cardBg = isPsychologistPost ? const Color(0xFFEADDFF) : surface;
    final Color accentColor = isPsychologistPost ? deep : primary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPsychologistPost ? medium.withOpacity(0.5) : rule,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPsychologistPost ? primary : medium,
                  radius: 18,
                  child: Icon(
                    isPsychologistPost ? Icons.psychology : Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPsychologistPost ? "Dr. Psychologist" : "Parent User",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPsychologistPost ? deep : inkDark,
                        ),
                      ),
                      Text(
                        isPsychologistPost
                            ? "Verified Expert"
                            : "Community Member",
                        style: const TextStyle(fontSize: 10, color: inkMuted),
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  const Icon(Icons.check_circle, color: primary, size: 16),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['post_title'] ?? "",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post['post_details'] ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    color: inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (post['post_file'] != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post['post_file'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // ── Action Row: Reply and Like ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reply Button
                GestureDetector(
                  onTap: () => _showSnackBar(
                    "Opening replies for: ${post['post_title']}",
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: primary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Reply",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Like Button
                GestureDetector(
                  onTap: () => _likePost(pid),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : inkMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$count",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isLiked ? Colors.red : inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
