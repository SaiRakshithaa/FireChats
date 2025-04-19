import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String errorMessage = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp() async {
    String username = usernameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = "All fields are required.";
      });
      return;
    }

    try {
      // ✅ Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Store user details in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "email": email,
        "username": username,
        "createdAt": FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Go back on successful signup
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage("assets/background.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Fire Chat',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF075E54),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/background.png",
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.2),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Container(
                padding: EdgeInsets.all(25),
                width: 350,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black26,
                      spreadRadius: 3,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "SIGN UP",
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF075E54)),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF075E54), width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF075E54), width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF075E54), width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: signUp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25D366)),
                      child: Text("Sign Up", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(
                                text: "Sign In",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

