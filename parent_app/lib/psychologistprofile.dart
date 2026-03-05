import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointmentbooking.dart';

class PsychologistProfile extends StatelessWidget {
  final Map<String, dynamic> psychologistData;
  const PsychologistProfile({super.key, required this.psychologistData});

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

  @override
  Widget build(BuildContext context) {
    final String? dbPhoto = psychologistData['psychologist_photo'];
    final String psychologistId = psychologistData['psychologist_id']
        .toString();
    final String storageUrl = Supabase.instance.client.storage
        .from('User')
        .getPublicUrl('$psychologistId.jpg');

    final name = psychologistData['psychologist_name'] ?? 'Expert Psychologist';
    final initials = name
        .toString()
        .trim()
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: surface,
            surfaceTintColor: Colors.transparent,
            elevation: 1,
            scrolledUnderElevation: 1,
            shadowColor: rule,
            automaticallyImplyLeading: false,
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: background,
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
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _buildHero(
                context,
                name,
                initials,
                dbPhoto,
                storageUrl,
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // About section
                  _buildSectionRule("ABOUT"),
                  const SizedBox(height: 16),
                  _buildAboutCard(),
                  const SizedBox(height: 28),

                  // Details
                  _buildSectionRule("DETAILS"),
                  const SizedBox(height: 16),
                  _buildDetailsCard(),
                  const SizedBox(height: 36),

                  // Booking button
                  _buildBookingButton(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO ────────────────────────────────────────────────────────────────────

  Widget _buildHero(
    BuildContext context,
    String name,
    String initials,
    String? dbPhoto,
    String storageUrl,
  ) {
    final hasPhoto =
        (dbPhoto != null && dbPhoto.isNotEmpty) || storageUrl.isNotEmpty;
    final imageProvider = (dbPhoto != null && dbPhoto.isNotEmpty)
        ? NetworkImage(dbPhoto)
        : NetworkImage(storageUrl);

    final email = psychologistData['psychologist_email'] ?? '';
    final qual = psychologistData['psychologist_qualification'] ?? '';

    return Container(
      color: surface,
      child: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: soft.withOpacity(0.45),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: soft.withOpacity(0.25),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(top: 80, bottom: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gradient ring avatar
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [medium, primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: soft,
                    backgroundImage: hasPhoto ? imageProvider : null,
                    child: !hasPhoto
                        ? Text(
                            initials,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: inkDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),

                // Email
                if (email.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 13,
                        color: inkMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 10),

                // Qualification pill
                if (qual.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: soft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      qual,
                      style: const TextStyle(
                        fontSize: 12,
                        color: primary,
                        fontWeight: FontWeight.w700,
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

  // ─── ABOUT CARD ──────────────────────────────────────────────────────────────

  Widget _buildAboutCard() {
    final qual =
        psychologistData['psychologist_qualification'] ?? 'Mental Health';
    return Container(
      width: double.infinity,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Specializing in $qual. Committed to providing compassionate care and evidence-based therapy for families and children.",
              style: const TextStyle(
                fontSize: 13.5,
                color: inkMuted,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── DETAILS CARD ────────────────────────────────────────────────────────────

  Widget _buildDetailsCard() {
    final details = [
      {
        "label": "Qualification",
        "value": psychologistData['psychologist_qualification'],
        "icon": Icons.school_outlined,
      },
      {
        "label": "Experience",
        "value": psychologistData['psychologist_experience'],
        "icon": Icons.work_outline_rounded,
      },
      {
        "label": "Contact",
        "value": psychologistData['psychologist_contact'],
        "icon": Icons.phone_outlined,
      },
    ];

    return Container(
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
        children: details.asMap().entries.map((entry) {
          final i = entry.key;
          final d = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: soft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        d['icon'] as IconData,
                        color: primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['label'] as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (d['value'] as String?) ?? 'Not specified',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: inkDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < details.length - 1)
                const Divider(
                  color: rule,
                  height: 1,
                  indent: 18,
                  endIndent: 18,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ─── BOOKING BUTTON ──────────────────────────────────────────────────────────

  Widget _buildBookingButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              Appointmentbooking(psychologistData: psychologistData),
        ),
      ),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [deep, primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.32),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              "Book Appointment",
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
