import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Parentlist extends StatefulWidget {
  const Parentlist({super.key});

  @override
  State<Parentlist> createState() => _ParentlistState();
}

class _ParentlistState extends State<Parentlist> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> allPatients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool _isLoading = true;
  String _searchQuery = "";

  final Color primaryPurple = const Color.fromRGBO(61, 14, 86, 1);

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Logic: Fetch all appointments for this psychologist and get unique parent/child info
      // You can adjust the join based on your exact table structure
      final List<dynamic> data = await supabase
          .from('tbl_appointment')
          .select('tbl_parent(parent_id, parent_name, parent_photo, parent_contact)')
          .eq('psychologist_id', user.id);

      // Filter for unique parents to avoid duplicates in the patient list
      final uniqueIds = <String>{};
      final uniquePatients = <Map<String, dynamic>>[];

      for (var item in data) {
        final parent = item['tbl_parent'] as Map<String, dynamic>?;
        if (parent != null && !uniqueIds.contains(parent['parent_id'])) {
          uniqueIds.add(parent['parent_id']);
          uniquePatients.add(parent);
        }
      }

      setState(() {
        allPatients = uniquePatients;
        filteredPatients = uniquePatients;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching patients: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _searchQuery = query;
      filteredPatients = allPatients
          .where((patient) => patient['parent_name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Patients", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryPurple))
                : filteredPatients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) => _buildPatientCard(filteredPatients[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          onChanged: _filterSearch,
          decoration: const InputDecoration(
            hintText: "Search patient name...",
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: primaryPurple.withOpacity(0.1),
          backgroundImage: patient['parent_photo'] != null ? NetworkImage(patient['parent_photo']) : null,
          child: patient['parent_photo'] == null 
              ? Icon(Icons.person, color: primaryPurple) : null,
        ),
        title: Text(patient['parent_name'] ?? "Unknown Name", 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Contact: ${patient['parent_contact'] ?? 'N/A'}", 
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            icon: Icon(Icons.message_outlined, color: primaryPurple, size: 20),
            onPressed: () {
              // Navigate to chat
            },
          ),
        ),
        onTap: () {
          // Navigate to detailed patient history/records
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 10),
          Text(_searchQuery.isEmpty ? "No patients assigned yet" : "No patient found with that name",
              style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}