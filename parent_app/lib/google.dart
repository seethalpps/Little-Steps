import 'package:parent_app/addchild.dart';
import 'package:parent_app/appointmentbooking.dart';
import 'package:parent_app/communitypost.dart';
import 'package:parent_app/homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';
import 'package:parent_app/myprofile.dart';
import 'package:parent_app/psychologistlist.dart';

class google extends StatefulWidget {
  @override
  _googleState createState() => _googleState();
}

class _googleState extends State<google> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
  );
  static const List<Widget> _widgetOptions = <Widget>[
    Homepage(),
    Communitypost(),
    PsychologistList(),
    Myprofile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(elevation: 20, title: const Text('GoogleNavBar')),
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 24,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: [
                GButton(icon: LineIcons.home, text: 'Home'),
                GButton(icon: LineIcons.comments, text: 'Post'),
                GButton(icon: LineIcons.search, text: 'Search'),
                GButton(icon: LineIcons.user, text: 'Profile'),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
