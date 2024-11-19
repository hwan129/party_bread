import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      await _handleUserSignIn(userCredential.user, isGoogleSignIn: true);
    } catch (e) {
      print("Error Google sign-in: $e");
    }
  }

  Future<void> _handleUserSignIn(User? user,
      {required bool isGoogleSignIn}) async {
    if (user == null) return;

    final userDoc = _firestore.collection('user').doc(user.uid);

    final userDocSnapshot = await userDoc.get();
    if (!userDocSnapshot.exists) {
      if (isGoogleSignIn) {
        await userDoc.set({
          'name': user.displayName,
          'email': user.email,
          'uid': user.uid,
          'status_message': "I promise to take the test honestly before GOD.",
        });
      } else {
        await userDoc.set({
          'uid': user.uid,
          'status_message': "I promise to take the test honestly before GOD.",
        });
      }
    }

    Navigator.pushReplacementNamed(
        context, '/onboarding'); // to onboarding page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: Text('Sign in with Google'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signupPhone');
              },
              child: Text('Sign Up with Phone Number'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
