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
          .eq('parent_id', userId);
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
            .eq('parent_id', userId);
      } else {
        await supabase.from('tbl_like').insert({
          'post_id': postId,
          'parent_id': userId,
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
        'parent_id': supabase.auth.currentUser?.id,
        'psychologist_id': null,
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
                // Handle bar
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

                // Header
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

                // Title field
                _sheetFieldLabel("Title"),
                _sheetTextField(
                  controller: _titleController,
                  hint: "What's on your mind?",
                  icon: Icons.title_rounded,
                ),
                const SizedBox(height: 16),

                // Description
                _sheetFieldLabel("Description"),
                _sheetTextField(
                  controller: _descriptionController,
                  hint: "Share more details...",
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Comment visibility
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

                // Media attach row
                GestureDetector(
                  onTap: () async {
                    final img = await _picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (img != null) {
                      setModalState(() => _tempPickedFile = img);
                    }
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
                        if (_tempPickedFile != null)
                          GestureDetector(
                            onTap: () =>
                                setModalState(() => _tempPickedFile = null),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.28),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isUploading
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
                                const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Share Post",
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
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            border: Border.all(
              color: isSelected ? primary : rule,
              width: isSelected ? 1.5 : 1,
            ),
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

  Widget _sheetFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: inkMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _sheetTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: inkDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: inkMuted.withOpacity(0.5), fontSize: 13.5),
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
          "Community",
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: inkDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _showAddPostSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deep, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Post",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
              child: _buildSearchBar(),
            ),
            const SizedBox(height: 18),

            // ── Tab switcher ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildTabSwitcher(),
            ),
            const SizedBox(height: 16),

            // ── Section rule ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildSectionRule(
                isShowingMyPosts ? "MY POSTS" : "ALL POSTS",
              ),
            ),
            const SizedBox(height: 12),

            // ── Post list ─────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: postStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: inkMuted),
                      ),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: primary,
                        strokeWidth: 2,
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];
                  final filtered = posts.where((p) {
                    final matchesTab = isShowingMyPosts
                        ? p['parent_id'] == userId
                        : true;
                    final matchesSearch =
                        searchQuery.isEmpty ||
                        (p['post_title'] as String).toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        );
                    return matchesTab && matchesSearch;
                  }).toList();

                  if (filtered.isEmpty) {
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
                              Icons.forum_outlined,
                              size: 36,
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            isShowingMyPosts
                                ? "You haven't posted yet"
                                : "No posts found",
                            style: const TextStyle(
                              color: inkMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Be the first to share!",
                            style: TextStyle(color: inkMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }

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

  // ─── SEARCH BAR ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => searchQuery = v),
        style: const TextStyle(
          fontSize: 14,
          color: inkDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Search posts...",
          hintStyle: TextStyle(
            color: inkMuted.withOpacity(0.5),
            fontSize: 13.5,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, color: medium, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => searchQuery = "");
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: primary,
                    ),
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // ─── TAB SWITCHER ────────────────────────────────────────────────────────────

  Widget _buildTabSwitcher() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rule),
      ),
      child: Row(
        children: [
          _tabOption(
            "My Posts",
            isShowingMyPosts,
            () => setState(() => isShowingMyPosts = true),
          ),
          _tabOption(
            "All Posts",
            !isShowingMyPosts,
            () => setState(() => isShowingMyPosts = false),
          ),
        ],
      ),
    );
  }

  Widget _tabOption(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [deep, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primary.withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isActive ? Colors.white : inkMuted,
              ),
            ),
          ),
        ),
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

  // ─── POST CARD ───────────────────────────────────────────────────────────────

  Widget _buildPostCard(Map<String, dynamic> post) {
    final int pid = post['post_id'];
    final bool isLiked = userLikes[pid] ?? false;
    final int count = likeCounts[pid] ?? 0;
    final bool isOwnPost = post['parent_id'] == supabase.auth.currentUser?.id;
    final int commentStatus =
        int.tryParse(post['comment_status'].toString()) ?? 2;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Post header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [medium, primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      isOwnPost
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOwnPost ? "You" : "Community Member",
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: inkDark,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            commentStatus == 1
                                ? Icons.psychology_outlined
                                : Icons.public_rounded,
                            size: 10,
                            color: inkMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            commentStatus == 1
                                ? "Psychologists only"
                                : "Everyone",
                            style: const TextStyle(
                              fontSize: 10,
                              color: inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOwnPost)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Your post",
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

          // ── Divider ─────────────────────────────────────────────────────
          const Divider(color: rule, height: 1),

          // ── Post content ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['post_title'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: inkDark,
                  ),
                ),
                if ((post['post_details'] ?? "").isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    post['post_details'] ?? "",
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: inkMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Image ────────────────────────────────────────────────────────
          if (post['post_file'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  post['post_file'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: inkMuted,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Like row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Just now",
                  style: TextStyle(
                    color: inkMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: () => _likePost(pid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isLiked ? const Color(0xFFFDE8EE) : background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isLiked
                            ? const Color(0xFF9B3A5A).withOpacity(0.4)
                            : rule,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: isLiked ? const Color(0xFF9B3A5A) : inkMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "$count",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isLiked ? const Color(0xFF9B3A5A) : inkMuted,
                          ),
                        ),
                      ],
                    ),
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
