import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final TextEditingController _categoryController = TextEditingController();
  List<Map<String, dynamic>> categoryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> insert() async {
    if (_categoryController.text.isEmpty) return; // Basic validation
    try {
      await supabase.from('tbl_category').insert({
        'category_name': _categoryController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Data Inserted..")));
      }
      _categoryController.clear();
      fetchData(); // Refresh the list
    } catch (e) {
      print("Insert Error: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      final data = await supabase.from('tbl_category').select();
      setState(() {
        categoryData = data;
        isLoading = false;
      });
    } catch (e) {
      print("Fetch Error: $e");
    }
  }

  void delCategory(int id) async {
    try {
      // Fixed typo: tbl_category
      await supabase.from('tbl_category').delete().eq('category_id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted Successfully")));
      }
      fetchData(); // Refresh the list
    } catch (e) {
      print("Delete Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Category Management")),
      body: Column(
        children: [
          // Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(95, 121, 85, 72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: insert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 63, 2, 2),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // List Section
          const Divider(),
          Expanded(
            // <--- This fixes the layout overflow/scroll issues
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: categoryData.length,
                    itemBuilder: (context, index) {
                      final item = categoryData[index];
                      return ListTile(
                        title: Text(item['category_name'] ?? 'No Name'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => delCategory(item['category_id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
