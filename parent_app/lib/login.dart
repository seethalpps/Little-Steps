import 'package:flutter/material.dart';
import 'package:parent_app/google.dart';
import 'package:parent_app/signup.dart';
import 'package:parent_app/homepage.dart'; // Ensure this path is correct
import 'package:parent_app/main.dart'; // To access the 'supabase' instance

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // 1. Define controllers for both Email and Password
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  // 2. Sign In Function
  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      // Supabase Authentication
      await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        // 3. Navigate to Homepage and clear the navigation stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => google()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SingleChildScrollView(
              child: Form(
                child: Column(
                  children: [
                    const SizedBox(height: 160),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        "assets/logo.png",
                        height: 100,
                        width: 100,
                      ),
                    ),
                    const Text(
                      "LOGIN",
                      style: TextStyle(
                        color: Color.fromRGBO(61, 14, 86, 1),
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Email Field
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Enter Email",
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 69, 8, 84),
                          ),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    ),
                    // Password Field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: TextFormField(
                        controller: passwordController,
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true, // Hides password
                        decoration: const InputDecoration(
                          labelText: "Enter Password",
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Login Button
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  61,
                                  14,
                                  86,
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Signup(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              "Don't have an account? Sign up",
                              style: TextStyle(
                                color: Color.fromRGBO(61, 14, 86, 1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
