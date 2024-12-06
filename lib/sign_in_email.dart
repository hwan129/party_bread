import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInEmailPage extends StatefulWidget {
  @override
  _SignInEmailPageState createState() => _SignInEmailPageState();
}

class _SignInEmailPageState extends State<SignInEmailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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

      // Firebase Authentication으로 로그인
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에서 사용자 문서 확인
      User? user = userCredential.user;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('user').doc(user.uid).get();

        if (userDoc.exists) {
          bool isNewUser = userDoc.get('isNewUser') ?? false; // 기본값 false

          if (isNewUser) {
            await _firestore
                .collection('user')
                .doc(user.uid)
                .update({'isNewUser': false}); // 신규 사용자 플래그 해제
            Navigator.pushReplacementNamed(context, '/onboarding');
          } else {
            Navigator.pushReplacementNamed(context, '/home'); // 기존 사용자 홈 페이지로 이동
          }
        } else {
          throw Exception("User document not found in Firestore.");
        }
      }
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
      appBar: AppBar(title: Text('이메일로 로그인')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("이메일", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '이메일을 입력하세요',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF574142), width: 1),
                    borderRadius: BorderRadius.circular(10),

                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF574142), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              Text("비밀번호", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: '비밀번호를 입력하세요',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF574142), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF574142), width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: _signInWithEmailAndPassword,
                child: Text('로그인 하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF574142),
                  foregroundColor: Color(0xFFF5E0D3),
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
