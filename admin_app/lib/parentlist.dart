import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Parentlist extends StatefulWidget {
  const Parentlist({super.key});

  @override
  State<Parentlist> createState() => _ParentlistState();
}

class _ParentlistState extends State<Parentlist> {
  final SupabaseClient supabase = Supabase.instance.client;

  // Stream configured for tbl_parent using parent_id as primary key
  final Stream<List<Map<String, dynamic>>> _parentStream = Supabase
      .instance
      .client
      .from('tbl_parent')
      .stream(primaryKey: ['parent_id']);

  // Delete function using the parent_id primary key
  Future<void> _deleteParent(dynamic id) async {
    try {
      await supabase.from('tbl_parent').delete().eq('parent_id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parent removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Management'),
        backgroundColor: const Color(0xFF673AB7), // Deep Purple theme
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _parentStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text('No parents found.'));
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
                    DataColumn(
                      label: Text(
                        'SL NO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Contact',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Address',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'DOJ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Actions',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    // Safety check for date string length to prevent RangeError
                    String createdAt = item['created_at']?.toString() ?? '';
                    String dateOnly = (createdAt.length >= 10)
                        ? createdAt.substring(0, 10)
                        : createdAt;

                    return DataRow(
                      cells: [
                        DataCell(Text((index + 1).toString())),
                        DataCell(
                          Text(item['parent_name']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(item['parent_email']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(item['parent_contact']?.toString() ?? 'N/A'),
                        ),
                        DataCell(
                          Text(item['parent_address']?.toString() ?? 'N/A'),
                        ),
                        DataCell(Text(dateOnly)),
                        DataCell(
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteParent(item['parent_id']),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
