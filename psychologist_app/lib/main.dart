import 'package:flutter/material.dart';
import 'package:psychologist_app/availabledate_time.dart';
import 'package:psychologist_app/homepage.dart';
import 'package:psychologist_app/landingpage.dart';
import 'package:psychologist_app/login.dart';
import 'package:psychologist_app/myprofile.dart';
import 'package:psychologist_app/parentlist.dart';

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
