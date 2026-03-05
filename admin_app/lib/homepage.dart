import 'package:admin_app/Category.dart';
import 'package:admin_app/Login.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/parentlist.dart';
import 'package:admin_app/place.dart';
import 'package:admin_app/psychologistlist.dart';
import 'package:admin_app/type.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectedIndex = 0;

  List<String> pageName = [
    'Dashboard',
    'Account',
    'District',
    'Place',
    'Psychologist List',
    'Parent List',
  ];

  List<IconData> pageIcon = [
    Icons.home,
    Icons.supervised_user_circle,
    Icons.map_outlined,
    Icons.location_on,
    Icons.psychology,
    Icons.escalator_warning,
  ];

  List<Widget> pageContent = [
    Category(),
    Type(),
    District(),
    Place(),
    Psychologistlist(),
    Parentlist(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: Row(
        children: [
          //Side Bar
          Expanded(
            flex: 1,
            child: Container(
              color: const Color.fromARGB(255, 194, 207, 218),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: pageName.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          leading: Icon(
                            pageIcon[index],
                            color: selectedIndex == index
                                ? Colors.white
                                : Colors.black,
                          ),
                          title: Text(
                            pageName[index],
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          tileColor: selectedIndex == index
                              ? Colors.blueAccent
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            flex: 5,
            child: Container(
              color: Colors.white,
              child: pageContent[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
