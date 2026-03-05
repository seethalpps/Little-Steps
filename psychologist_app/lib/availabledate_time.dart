import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AvailabledateTime extends StatefulWidget {
  final DateTime selectedDate;

  const AvailabledateTime({super.key, required this.selectedDate});

  @override
  State<AvailabledateTime> createState() => _AvailabledateTimeState();
}

class _AvailabledateTimeState extends State<AvailabledateTime> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();

  bool _isSubmitting = false;
  int _appointmentType = 0; // 0 for Offline, 1 for Online

  final Color primaryPurple = const Color(0xFF673AB7);

  String _formatToDbTime(String time12h) {
    if (time12h.isEmpty) return "";
    final date = DateFormat.jm().parse(time12h);
    return DateFormat("HH:mm:ss").format(date);
  }

  /// Validates if the selected time is in the past (only if date is today)
  bool _isTimeInPast(String timeStr) {
    final now = DateTime.now();
    final selectedDate = widget.selectedDate;

    // Check if the selected date is today
    bool isToday =
        selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (!isToday) return false; // Date is in the future, so time is fine

    final DateFormat format = DateFormat.jm();
    final DateTime pickedTime = format.parse(timeStr);

    // Create a DateTime object for today at the picked time
    final DateTime comparisonTime = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    return comparisonTime.isBefore(now);
  }

  /// Validates that End Time is after Start Time
  bool _isEndTimeAfterStart() {
    try {
      final DateFormat format = DateFormat.jm();
      final DateTime startTime = format.parse(_startTimeController.text);
      final DateTime endTime = format.parse(_endTimeController.text);
      return endTime.isAfter(startTime);
    } catch (e) {
      return false;
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        controller.text = DateFormat.jm().format(dt);
      });
    }
  }

  Future<void> _submitAvailability() async {
    // 1. Check empty fields
    if (_startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
      _showSnackBar("Please fill both time fields", Colors.orange);
      return;
    }

    // 2. Check if Start Time has already passed (if today)
    if (_isTimeInPast(_startTimeController.text)) {
      _showSnackBar("The start time has already passed", Colors.redAccent);
      return;
    }

    // 3. Check if End Time is after Start Time
    if (!_isEndTimeAfterStart()) {
      _showSnackBar("End time must be after start time", Colors.redAccent);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      await supabase.from('tbl_availability').insert({
        'psychologist_id': user.id,
        'available_date': DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        'start_time': _formatToDbTime(_startTimeController.text),
        'end_time': _formatToDbTime(_endTimeController.text),
        'appointment_type': _appointmentType,
      });

      if (mounted) {
        _showSnackBar("Availability Saved!", Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Set Availability"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date: ${DateFormat('EEEE, MMM d, yyyy').format(widget.selectedDate)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),

            _buildLabel("Appointment Type"),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Offline")),
                    selected: _appointmentType == 0,
                    selectedColor: primaryPurple.withOpacity(0.2),
                    onSelected: (bool selected) {
                      if (selected) setState(() => _appointmentType = 0);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text("Online")),
                    selected: _appointmentType == 1,
                    selectedColor: primaryPurple.withOpacity(0.2),
                    onSelected: (bool selected) {
                      if (selected) setState(() => _appointmentType = 1);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            _buildLabel("Start Time"),
            _buildTimeField(_startTimeController, "Pick start time"),
            const SizedBox(height: 20),
            _buildLabel("End Time"),
            _buildTimeField(_endTimeController, "Pick end time"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAvailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Availability",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  Widget _buildTimeField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectTime(controller),
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: Icon(Icons.access_time, color: primaryPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
