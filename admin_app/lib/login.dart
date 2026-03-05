import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController login = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          child: Column(
            children: [
              Container(height: 450, width: 450),

              Text(
                "LOGIN",
                style: TextStyle(
                  color: const Color.fromRGBO(61, 14, 86, 1),
                  fontSize: 30,
                ),
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: TextFormField(
                  controller: login,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    label: Text(" Email"),
                    labelStyle: TextStyle(
                      color: const Color.fromARGB(255, 69, 8, 84),
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    label: Text(" Password"),
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 61, 14, 86),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
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
