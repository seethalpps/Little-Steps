import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  final TextEditingController _placeController = TextEditingController();
  List<Map<String, dynamic>> placeData = [];
  List<Map<String, dynamic>> districtData = [];
  bool isLoading = true;

  dynamic _selectedDistrict;
  int eid = 0;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    setState(() => isLoading = true);
    await fetchDistricts();
    await fetchData();
    setState(() => isLoading = false);
  }

  Future<void> fetchDistricts() async {
    try {
      final response = await supabase
          .from('tbl_district')
          .select()
          .order('district_name');
      setState(() {
        districtData = response;
      });
    } catch (e) {
      debugPrint("District Fetch Error: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      final data = await supabase
          .from('tbl_place')
          .select('*, tbl_district(district_name)')
          .order('place_id');
      setState(() {
        placeData = data;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  Future<void> insert() async {
    if (_placeController.text.isEmpty || _selectedDistrict == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    try {
      await supabase.from('tbl_place').insert({
        'place_name': _placeController.text.trim(),
        'district_id': _selectedDistrict,
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Data Inserted..")));
      }
      _placeController.clear();
      setState(() => _selectedDistrict = null);
      fetchData();
    } catch (e) {
      debugPrint("Insert Error: $e");
    }
  }

  void delPlace(int id) async {
    try {
      await supabase.from('tbl_place').delete().eq('place_id', id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Deleted Successfully")));
      }
      fetchData();
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  // --- UPDATED EDIT FUNCTION ---
  Future<void> editPlace(int id) async {
    try {
      await supabase
          .from('tbl_place')
          .update({
            'place_name': _placeController.text.trim(),
            'district_id': _selectedDistrict, // Now updates District too
          })
          .eq('place_id', id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Updated Successfully")));
      }
      _placeController.clear();
      setState(() => _selectedDistrict = null);
      fetchData();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Place Management")),
      body: Column(
        children: [
          // Input Section (Add New)
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
                  DropdownButtonFormField(
                    value: _selectedDistrict,
                    items: districtData.map((district) {
                      return DropdownMenuItem(
                        value: district['district_id'],
                        child: Text(district['district_name'] ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Select District",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      labelText: "Place Name",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: insert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 63, 2, 2),
                      minimumSize: const Size(double.infinity, 45),
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
                : Column(
                    children: [
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
                              flex: 2,
                              child: Text(
                                "District",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Place",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2, // Increased flex for Row of icons
                              child: Text(
                                "Actions",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: placeData.length,
                          itemBuilder: (context, index) {
                            final item = placeData[index];
                            String dName =
                                item['tbl_district']?['district_name'] ?? 'N/A';

                            return Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.black12),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text("${index + 1}"),
                                    ),
                                    Expanded(flex: 2, child: Text(dName)),
                                    Expanded(
                                      flex: 2,
                                      child: Text(item['place_name'] ?? ''),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () {
                                              // SET INITIAL VALUES FOR EDIT
                                              setState(() {
                                                eid = item['place_id'];
                                                _placeController.text =
                                                    item['place_name'] ?? '';
                                                _selectedDistrict =
                                                    item['district_id'];
                                              });

                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  // StatefulBuilder allows UI to update inside Dialog
                                                  return StatefulBuilder(
                                                    builder: (context, setDialogState) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          "Edit Place",
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            DropdownButtonFormField(
                                                              value:
                                                                  _selectedDistrict,
                                                              items: districtData.map((
                                                                dist,
                                                              ) {
                                                                return DropdownMenuItem(
                                                                  value:
                                                                      dist['district_id'],
                                                                  child: Text(
                                                                    dist['district_name'] ??
                                                                        'Unknown',
                                                                  ),
                                                                );
                                                              }).toList(),
                                                              onChanged: (val) {
                                                                setDialogState(
                                                                  () =>
                                                                      _selectedDistrict =
                                                                          val,
                                                                );
                                                                setState(
                                                                  () =>
                                                                      _selectedDistrict =
                                                                          val,
                                                                );
                                                              },
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        "District",
                                                                  ),
                                                            ),
                                                            TextFormField(
                                                              controller:
                                                                  _placeController,
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        "Place Name",
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                  context,
                                                                ),
                                                            child: const Text(
                                                              "Cancel",
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              editPlace(eid);
                                                              Navigator.pop(
                                                                context,
                                                              );
                                                            },
                                                            child: const Text(
                                                              "Update",
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
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
                                            onPressed: () =>
                                                delPlace(item['place_id']),
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
