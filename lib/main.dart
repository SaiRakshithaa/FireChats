import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'Login.dart';

Future main() async{
  WidgetsFlutterBinding.ensureInitialized();
  if(kIsWeb){
    await Firebase.initializeApp(options: FirebaseOptions(apiKey: "AIzaSyAnJF6dM0TS1-KV4Recv_KlOiFkpErnEmU", appId: "1:501089290108:web:c1e9c7c9447ebd7f0f46f9", messagingSenderId: "501089290108", projectId:"websocket-project-7a73c"));
  }
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:SignInScreen(),
     
    );
  }
}




