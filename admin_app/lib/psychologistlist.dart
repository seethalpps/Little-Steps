import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Psychologistlist extends StatefulWidget {
  const Psychologistlist({super.key});

  @override
  State<Psychologistlist> createState() => _PsychologistlistState();
}

class _PsychologistlistState extends State<Psychologistlist> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Stream listening to psychologist data in real-time
  final Stream<List<Map<String, dynamic>>> _psychologistStream = Supabase
      .instance
      .client
      .from('tbl_psychologist')
      .stream(primaryKey: ['id']);

  // Delete function for removing a record
  Future<void> _deletePsychologist(int id) async {
    try {
      await supabase.from('tbl_psychologist').delete().eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Psychologist removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Psychologist Management'),
        backgroundColor: const Color(0xFF673AB7), // Deep Purple
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _psychologistStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text('No psychologists found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.deepPurple.withOpacity(0.1),
                  ),
                  columns: const [
                    DataColumn(label: Text('SL NO')),
                    DataColumn(label: Text('Photo')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Contact')),
                    DataColumn(label: Text('Qualifications')),
                    DataColumn(label: Text('Experience')),
                    DataColumn(label: Text('Proof')),
                    DataColumn(label: Text('DOJ')),
                    DataColumn(
                      label: Text('Actions'),
                    ), // Kept for Delete button
                  ],
                  rows: List<DataRow>.generate(data.length, (index) {
                    final item = data[index];

                    return DataRow(
                      cells: [
                        DataCell(Text((index + 1).toString())),
                        DataCell(
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFEDE7F6),
                            backgroundImage: item['psychologist_photo'] != null
                                ? NetworkImage(item['psychologist_photo'])
                                : null,
                            child: item['psychologist_photo'] == null
                                ? const Icon(
                                    Icons.person,
                                    size: 20,
                                    color: Color(0xFF673AB7),
                                  )
                                : null,
                          ),
                        ),
                        DataCell(
                          Text(item['psychologist_name']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(item['psychologist_email']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(
                            item['psychologist_contact']?.toString() ?? 'N/A',
                          ),
                        ),
                        DataCell(
                          Text(
                            item['psychologist_qualification']?.toString() ??
                                'N/A',
                          ),
                        ),
                        DataCell(
                          Text(
                            "${item['psychologist_experience'] ?? '0'} Years",
                          ),
                        ),
                        DataCell(
                          const Icon(
                            Icons.file_present,
                            color: Colors.blueGrey,
                          ),
                        ),
                        DataCell(
                          Text(
                            item['created_at']?.toString().substring(0, 10) ??
                                '',
                          ),
                        ),
                        DataCell(
                          // Removed the Edit IconButton, leaving only Delete
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deletePsychologist(item['id']),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
