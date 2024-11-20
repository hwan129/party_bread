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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
      // 사용자가 처음 로그인하는 경우
      await userDoc.set({
        'name': isGoogleSignIn ? user.displayName : null,
        'email': user.email,
        'uid': user.uid,
        'isNewUser': false, // 새로운 사용자 플래그
      });
      print("new");
      Navigator.pushReplacementNamed(context, '/onboarding'); // 온보딩 페이지로 이동
    } else {
      print("not new");
      // 기존 사용자라면 isNewUser 플래그 확인
      bool isNewUser = userDocSnapshot.data()?['isNewUser'] ?? false;
      if (isNewUser) {
        // 신규 사용자일 경우 isNewUser 플래그를 false로 업데이트
        await userDoc.update({
          'isNewUser': false,
        });

        // 온보딩 페이지로 이동
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        // 기존 사용자라면 홈 페이지로 이동
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _handleUserSignIn(userCredential.user, isGoogleSignIn: false);
    } catch (e) {
      print("Error Email/Password sign-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signInWithEmailAndPassword,
                child: Text('Login'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Text('Sign in with Google'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text('Sign Up with Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
