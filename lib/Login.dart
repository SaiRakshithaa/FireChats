import 'package:flutter/material.dart';
import 'Signup.dart';
import 'Firebase_auth.dart';
import 'ChatScreenList.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = "";

  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    String? error = await AuthService().signIn(email, password);
    if (error == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => SearchUsersScreen()));
    } else {
      setState(() {
        errorMessage = error;
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
        title: Text('Fire Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF075E54),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/background.png", fit: BoxFit.cover),
          ),
          Container(color: Colors.white.withOpacity(0.2)),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Container(
                padding: EdgeInsets.all(25),
                width: 350,
                height: 350,
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
                    Text("LOGIN",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF075E54))),
                    SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF075E54), width: 2.0),
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
                          borderSide:
                              BorderSide(color: Color(0xFF075E54), width: 2.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    if (errorMessage.isNotEmpty)
                      Text(errorMessage, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: login,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF25D366)),
                      child:
                          Text("Login", style: TextStyle(color: Colors.white)),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignUpScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
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
