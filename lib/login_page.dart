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

  final String logoImageUrl =
      "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/login_image.png?alt=media&token=fe19dd66-f5c4-48dc-abd0-c41cacad00d9";

  Future<void> _signInWithGoogle() async {
    try {
      // 로그아웃 후 새 계정 선택하도록 설정
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
      // 새로운 사용자 Firestore에 추가
      await userDoc.set({
        'name': isGoogleSignIn ? user.displayName : '사용자 이름',
        'nickname': isGoogleSignIn ? user.displayName : '사용자 이름',
        'email': user.email ?? '이메일 없음',
        'uid': user.uid,
        'isNewUser': false,
        'interactedDocs': [],
        'profileImage':
            "https://firebasestorage.googleapis.com/v0/b/party-bread.firebasestorage.app/o/potbbang.png?alt=media&token=d0f000c8-3dee-4cb0-8461-4d7bbf136c4b",
      });
      Navigator.pushReplacementNamed(context, '/onboarding'); // 온보딩 페이지로 이동
    } else {
      bool isNewUser = userDocSnapshot.data()?['isNewUser'] ?? false;
      if (isNewUser) {
        await userDoc.update({'isNewUser': false});
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        Navigator.pushReplacementNamed(context, '/home'); // 기존 사용자 홈 페이지로 이동
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF574142), // 배경 색상
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            Image.network(
              logoImageUrl,
              height: 500, // 이미지 크기 조정
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.error,
                size: 100,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 0),
            // 구글 로그인 버튼
            ElevatedButton.icon(
              onPressed: _signInWithGoogle,
              icon: Icon(Icons.login, color: Color(0xFF5B3A30)),
              label: Text('Sign in with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5E0D3),
                foregroundColor: Color(0xFF5B3A30),
                minimumSize: Size(300, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: 16),
            // 이메일 로그인 버튼
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/sign_in_email');
              },
              icon: Icon(Icons.email, color: Color(0xFF5B3A30)),
              label: Text('Sign in with Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5E0D3),
                foregroundColor: Color(0xFF5B3A30),
                minimumSize: Size(300, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            SizedBox(height: 16),
            // 회원가입 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text('Sign Up with Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF5E0D3),
                foregroundColor: Color(0xFF5B3A30),
                minimumSize: Size(300, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
