import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'psychologistprofile.dart';

class PsychologistList extends StatefulWidget {
  const PsychologistList({super.key});

  @override
  State<PsychologistList> createState() => _PsychologistListState();
}

class _PsychologistListState extends State<PsychologistList>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom app bar ─────────────────────────────────────────────
              _buildAppBar(),
              const SizedBox(height: 8),

              // ── Section rule ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: _buildSectionRule("AVAILABLE EXPERTS"),
              ),
              const SizedBox(height: 16),

              // ── Grid ───────────────────────────────────────────────────────
              Expanded(child: _buildGrid()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
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
              const SizedBox(width: 14),
              // Header text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Find your expert",
                      style: TextStyle(
                        fontSize: 12,
                        color: inkMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "Psychologists",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: inkDark,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Search bar
          _buildSearchBar(),
        ],
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rule),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(
          fontSize: 14,
          color: inkDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: "Search by name...",
          hintStyle: TextStyle(
            color: inkMuted.withOpacity(0.5),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 10),
            child: Icon(Icons.search_rounded, color: medium, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
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

  // ─── GRID ────────────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('tbl_psychologist')
          .stream(primaryKey: ['psychologist_id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: inkMuted),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primary, strokeWidth: 2),
          );
        }

        final psychologists = (snapshot.data ?? []).where((p) {
          final name = p['psychologist_name']?.toString().toLowerCase() ?? '';
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (psychologists.isEmpty) {
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
                    Icons.search_off_rounded,
                    size: 36,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "No experts found",
                  style: TextStyle(
                    color: inkMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Try a different search term",
                  style: TextStyle(color: inkMuted, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: psychologists.length,
          itemBuilder: (context, index) =>
              _buildPsychologistCard(psychologists[index]),
        );
      },
    );
  }

  // ─── PSYCHOLOGIST CARD ───────────────────────────────────────────────────────

  Widget _buildPsychologistCard(Map<String, dynamic> data) {
    final name = data['psychologist_name'] ?? 'Expert';
    final qual = data['psychologist_qualification'] ?? 'Specialist';
    final photo = data['psychologist_photo'];

    final initials = name
        .toString()
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PsychologistProfile(psychologistData: data),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: rule),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Avatar ──────────────────────────────────────────────────────
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [medium, primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 36,
                      backgroundColor: soft,
                      backgroundImage: photo != null
                          ? NetworkImage(photo)
                          : null,
                      child: photo == null
                          ? Text(
                              initials,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Verified badge
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D9A6B),
                        shape: BoxShape.circle,
                        border: Border.all(color: surface, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Name ────────────────────────────────────────────────────────
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: inkDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // ── Qualification pill ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  qual,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: inkMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),

              // ── View Profile button ──────────────────────────────────────
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [deep, primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "View Profile",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
