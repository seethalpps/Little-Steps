import 'package:flutter/material.dart';
import 'package:parent_app/addchild.dart';
import 'package:parent_app/appointmentbooking.dart';
import 'package:parent_app/changepass.dart';
import 'package:parent_app/consultform.dart';
import 'package:parent_app/google.dart';
import 'package:parent_app/homepage.dart';
import 'package:parent_app/login.dart';
import 'package:parent_app/myprofile.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://odaiviqepfmpcwiyuypm.supabase.co',
    anonKey: 'sb_publishable_cByJXB25IWuMkkg9NzSbbQ__jVdkLW3',
  );
  runApp(MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Scaffold(body: Login()));
  }
}
