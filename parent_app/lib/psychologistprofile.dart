import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'appointmentbooking.dart';

class PsychologistProfile extends StatelessWidget {
  final Map<String, dynamic> psychologistData;
  const PsychologistProfile({super.key, required this.psychologistData});

  // Theme Colors
  final Color primaryPurple = const Color(0xFF673AB7);
  final Color accentCanvas = const Color(0xFFF8F9FE);

  @override
  Widget build(BuildContext context) {
    // Determine the photo source
    final String? dbPhoto = psychologistData['psychologist_photo'];
    final String psychologistId = psychologistData['psychologist_id']
        .toString();

    // Fallback URL logic if psychologist_photo is just a filename and not a full URL
    final String storageUrl = Supabase.instance.client.storage
        .from('User')
        .getPublicUrl('$psychologistId.jpg');

    return Scaffold(
      backgroundColor: accentCanvas,
      body: CustomScrollView(
        slivers: [
          // Modern collapsing app bar effect
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: accentCanvas,
            elevation: 0,
            floating: true,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            centerTitle: true,
            title: const Text(
              "Profile Details",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(dbPhoto, storageUrl),
                  const SizedBox(height: 30),

                  _buildInfoSection(
                    label: "About Expert",
                    content:
                        "Specializing in ${psychologistData['psychologist_qualification'] ?? 'Mental Health'}. "
                        "Committed to providing compassionate care and evidence-based therapy.",
                    icon: Icons.info_outline,
                  ),

                  const SizedBox(height: 20),
                  _buildDetailCard(
                    "Qualification",
                    psychologistData['psychologist_qualification'],
                    Icons.school_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    "Experience",
                    psychologistData['psychologist_experience'],
                    Icons.work_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    "Contact Info",
                    psychologistData['psychologist_contact'],
                    Icons.phone_outlined,
                  ),

                  const SizedBox(height: 40),
                  _buildBookingButton(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String? dbPhoto, String storageUrl) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryPurple.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 65,
              backgroundColor: Colors.white,
              backgroundImage: (dbPhoto != null && dbPhoto.isNotEmpty)
                  ? NetworkImage(dbPhoto)
                  : NetworkImage(storageUrl),
              child: null, // Image takes precedence
            ),
          ),
          const SizedBox(height: 16),
          Text(
            psychologistData['psychologist_name'] ?? 'Expert Psychologist',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            psychologistData['psychologist_email'] ?? 'No email provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String label,
    required String content,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryPurple),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.6),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String title, String? value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not specified',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  Appointmentbooking(psychologistData: psychologistData),
            ),
          );
        },
        child: const Text(
          "Book Appointment",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
