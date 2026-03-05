import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;
  List notifications = [];
  bool loading = true;

  static const Color deep = Color(0xFF2D1B5E);
  static const Color primary = Color(0xFF7B5EA7);
  static const Color soft = Color(0xFFD4C4EE);
  static const Color background = Color(0xFFF0EBF9);
  static const Color inkMuted = Color(0xFF7B6A9A);

  @override
  void initState() {
    super.initState();
    getNotifications();
  }

  Future<void> getNotifications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint("No user logged in");
        return;
      }

      // 1. Check if column name is parent_id or user_id in your DB!
      final response = await supabase
          .from('tbl_notification')
          .select()
          .eq('parent_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          notifications = response;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching tbl_notification: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> markAsRead(dynamic id) async {
    try {
      await supabase
          .from('tbl_notification')
          .update({'is_read': true})
          .eq('id', id);
      getNotifications();
    } catch (e) {
      debugPrint("Error marking as read: $e");
    }
  }

  Future<void> deleteNotification(dynamic id, int index) async {
    try {
      setState(() {
        notifications.removeAt(index);
      });

      // Fixed typo: tbl_notification
      await supabase.from('tbl_notification').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting: $e");
      getNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: deep),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: deep,
            fontSize: 24,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final data = notifications[index];
                bool isRead = data['is_read'] ?? false;
                DateTime createdAt = data['created_at'] != null
                    ? DateTime.parse(data['created_at'])
                    : DateTime.now();

                return Dismissible(
                  key: Key(data['id'].toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => deleteNotification(data['id'], index),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.white,
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => markAsRead(data['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.white.withOpacity(0.6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRead ? Colors.transparent : soft,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isRead ? background : soft,
                            child: Icon(
                              isRead
                                  ? Icons.notifications_none
                                  : Icons.notifications_active,
                              color: isRead ? inkMuted : primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['notification_title'] ??
                                      "Update", // Check column name!
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.w600
                                        : FontWeight.w800,
                                    color: deep,
                                  ),
                                ),
                                Text(
                                  data['notification_message'] ??
                                      "", // Check column name!
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('jm').format(createdAt),
                            style: const TextStyle(
                              fontSize: 10,
                              color: inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: soft),
          const SizedBox(height: 16),
          const Text(
            "All caught up!",
            style: TextStyle(color: inkMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
