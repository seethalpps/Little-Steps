//import 'dart:ffi';

import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

class Type extends StatefulWidget {
  const Type({super.key});

  @override
  State<Type> createState() => _TypeState();
}

class _TypeState extends State<Type> {
  final TextEditingController _type = TextEditingController();
  Future<void> insert() async {
    try {
      await supabase.from('tbl_type').insert({'type_name': _type.text});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("data inserted")));
      _type.clear();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: Form(
        child: Container(
          height: 150,
          width: 450,
          color: const Color.fromARGB(95, 57, 106, 118),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextFormField(
                controller: _type,
                decoration: InputDecoration(
                  label: Text("Type"),
                  labelStyle: TextStyle(color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  insert();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(193, 19, 147, 239),
                ),
                child: Text(
                  "Submit",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
