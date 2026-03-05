import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ReportChart extends StatefulWidget {
  const ReportChart({super.key});

  @override
  State<ReportChart> createState() => _ReportChartState();
}

class _ReportChartState extends State<ReportChart> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<FlSpot> _chartPoints = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchMonthlyData();
  }

  // Real-time data fetching from Supabase
  Future<void> fetchMonthlyData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Defining the month range for the query
      final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
      final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

      // Fetching real data from 'tbl_appointment' table
      final response = await supabase
          .from('tbl_appointment')
          .select('appointment_date')
          .eq('psychologist_id', user.id)
          .gte('appointment_date', DateFormat('yyyy-MM-dd').format(firstDay))
          .lte('appointment_date', DateFormat('yyyy-MM-dd').format(lastDay));

      final List data = response as List;

      // Grouping data: Map<DayOfMonth, CountOfPatients>
      Map<int, int> countsByDay = {};
      for (var record in data) {
        DateTime date = DateTime.parse(record['appointment_date']);
        countsByDay[date.day] = (countsByDay[date.day] ?? 0) + 1;
      }

      // Creating a continuous line by filling 1..31 days
      List<FlSpot> points = [];
      for (int i = 1; i <= lastDay.day; i++) {
        points.add(FlSpot(i.toDouble(), (countsByDay[i] ?? 0).toDouble()));
      }

      setState(() => _chartPoints = points);
    } catch (e) {
      debugPrint("Supabase Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showScrollPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      fetchMonthlyData();
                      Navigator.pop(context);
                    },
                    child: const Text("Done"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.monthYear,
                initialDateTime: _selectedDate,
                onDateTimeChanged: (date) =>
                    setState(() => _selectedDate = date),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("< Growth report", style: TextStyle(fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showScrollPicker,
                child: Text(
                  DateFormat(
                    '< MMMM yyyy >',
                  ).format(_selectedDate).toLowerCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Horizontal Label: Patients
            const Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: Text("Patients", style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 5),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text("days", style: TextStyle(fontSize: 16)),
            axisNameSize: 30,
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2, // 2, 4, 6... for readability
              getTitlesWidget: (val, meta) => Text(
                val.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1, // Every number 1, 2, 3... upto 30
              getTitlesWidget: (value, meta) {
                if (value == 0)
                  return const Text("0", style: TextStyle(fontSize: 10));
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 2),
            left: BorderSide(color: Colors.black, width: 2),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _chartPoints, // Using real data points
            isCurved: true,
            color: Colors.black,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        minX: 0,
        minY: 0,
        maxY: 30, // Limit set to 30
      ),
    );
  }
}
