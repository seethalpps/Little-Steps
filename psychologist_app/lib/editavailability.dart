import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class Editavailability extends StatefulWidget {
  const Editavailability({super.key});

  @override
  State<Editavailability> createState() => _EditavailabilityState();
}

class _EditavailabilityState extends State<Editavailability> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> _availabilityList = [];
  bool _isLoading = true;

  final Color primaryPurple = const Color(0xFF673AB7);

  @override
  void initState() {
    super.initState();
    _fetchAvailability();

    //hi
  }

  // --- Fetch Availability from Supabase ---
  Future<void> _fetchAvailability() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('tbl_availability')
          .select()
          .eq('psychologist_id', userId)
          .order('available_date', ascending: true);

      if (mounted) {
        setState(() {
          _availabilityList = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Delete Slot Logic ---
  Future<void> _deleteSlot(dynamic id) async {
    debugPrint("Attempting to delete availability_id: $id");
    try {
      await supabase
          .from('tbl_availability')
          .delete()
          .eq('availability_id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Availability removed")));
        _fetchAvailability(); // Refresh list
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Edit Slot Logic (Start and End Time) ---
  Future<void> _editTimeRange(dynamic id) async {
    final TimeOfDay? startPicked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "Select New Start Time",
    );

    if (startPicked == null) return;

    if (mounted) {
      final TimeOfDay? endPicked = await showTimePicker(
        context: context,
        initialTime: startPicked,
        helpText: "Select New End Time",
      );

      if (endPicked == null) return;

      final formattedStart = startPicked.format(context);
      final formattedEnd = endPicked.format(context);

      try {
        await supabase
            .from('tbl_availability')
            .update({'start_time': formattedStart, 'end_time': formattedEnd})
            .eq('availability_id', id);

        if (mounted) _fetchAvailability();
      } catch (e) {
        debugPrint("Update Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9FF),
      appBar: AppBar(
        title: const Text(
          "Manage Availability",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPurple))
          : _availabilityList.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availabilityList.length,
              itemBuilder: (context, index) {
                final item = _availabilityList[index];
                final date = DateTime.parse(item['available_date']);
                final id = item['availability_id'];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryPurple.withOpacity(0.1),
                          child: Icon(
                            Icons.access_time_filled,
                            color: primaryPurple,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMM d').format(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${item['start_time'] ?? 'N/A'} - ${item['end_time'] ?? 'N/A'}",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editTimeRange(id),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: "Edit Slot",
                            ),
                            IconButton(
                              onPressed: () => _showDeleteDialog(id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: "Delete Slot",
                            ),
                          ],
                        ),
                      ],
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
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No availability slots found.",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Availability?"),
        content: const Text(
          "Are you sure? This will remove the slot for parents.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSlot(id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
