import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  final TextEditingController _districtController = TextEditingController();
  List<Map<String, dynamic>> districtData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // --- Database Operations ---

  Future<void> insert() async {
    if (_districtController.text.trim().isEmpty) return;
    try {
      await supabase.from('tbl_district').insert({
        'district_name': _districtController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data Inserted Successfully")),
        );
      }
      _districtController.clear();
      fetchData(); // Refresh the list
    } catch (e) {
      debugPrint("Insert Error: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      // Order by district_id or name to keep the list consistent
      final data = await supabase
          .from('tbl_district')
          .select()
          .order('district_id');
      setState(() {
        districtData = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> delDistrict(int id) async {
    try {
      await supabase.from('tbl_district').delete().eq('district_id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted Successfully")));
      }
      fetchData(); // Refresh the list
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  int eid = 0;
  Future<void> edit(int eid) async {
    try {
      await supabase
          .from('tbl_district')
          .update({'district_name': _districtController.text})
          .eq('district_id', eid);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
      }
      _districtController.clear();
      fetchData(); // Refresh the list
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  // --- UI Components ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("District Management"),
        backgroundColor: const Color.fromARGB(255, 63, 2, 2),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Input Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(40, 121, 85, 72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(
                      labelText: "District Name",
                      hintText: "Enter district name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: insert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 63, 2, 2),
                      minimumSize: const Size(120, 45),
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

          const Divider(thickness: 2),

          // Table Section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : districtData.isEmpty
                ? const Center(child: Text("No districts found."))
                : Column(
                    children: [
                      // Table Header
                      Container(
                        color: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                "SLNO",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                "District",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                "Actions",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table Body
                      Expanded(
                        child: ListView.builder(
                          itemCount: districtData.length,
                          itemBuilder: (context, index) {
                            final item = districtData[index];
                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    // SLNO
                                    Expanded(
                                      flex: 1,
                                      child: Text("${index + 1}"),
                                    ),
                                    // District Name
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        item['district_name'] ?? 'N/A',
                                      ),
                                    ),
                                    // Actions
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                eid = item['district_id'];
                                                _districtController.text =
                                                    item['district_name'] ?? '';
                                              });
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                      "Edit District",
                                                    ),
                                                    content: TextFormField(
                                                      controller:
                                                          _districtController,
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                "District Name",
                                                            filled: true,
                                                            fillColor:
                                                                Colors.white,
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        child: const Text(
                                                          "Cancel",
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          edit(eid);
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color.fromARGB(
                                                                255,
                                                                63,
                                                                2,
                                                                2,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          "Update",
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),

                                            onPressed: () => delDistrict(
                                              item['district_id'],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
