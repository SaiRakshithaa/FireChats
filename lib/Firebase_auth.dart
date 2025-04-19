import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> saveUserToFirestore(User user, String name) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        "uid": user.uid,
        "email": user.email,
        "name": name,
        "profilePic": "", // Placeholder for future profile pic updates
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving user to Firestore: $e");
    }
  }

  // Sign Up Function (Creates User & Stores in Firestore)
  Future<String?> signUp(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Update Firebase Auth display name
        await user.updateDisplayName(name);
        await user.reload(); // Refresh user data

        // Save user details to Firestore
        await saveUserToFirestore(user, name);

        print("User successfully registered: ${user.uid}");
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("Sign Up Error: $e");
      return e.message;
    }
  }

  // Sign In Function
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      print("Sign In Error: $e");
      return e.message;
    }
  }

  // Sign Out Function
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

