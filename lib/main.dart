import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_email_page.dart';
import 'signup_phone_page.dart';
import 'signup_name_page.dart';
import 'signup_nickname_page.dart';
import 'location_permission_page.dart';
import 'onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/Login', // 시작 페이지 설정
      routes: {
        '/Login': (context) => LoginPage(), // 로그인 페이지
        '/signupEmail': (context) => SignupEmailPage(), // 회원가입 - 이메일 입력 페이지
        '/signupPhone': (context) => SignupPhonePage(), // 회원가입 - 전화번호 입력 페이지
        '/signupName': (context) => SignupNamePage(), // 회원가입 - 이름 입력 페이지
        '/signupNickname': (context) =>
            SignupNicknamePage(), // 회원가입 - 닉네임 입력 페이지
        '/locationPermission': (context) =>
            LocationPermissionPage(), // 위치 정보 확인 페이지
        '/onboarding': (context) => OnboardingPage(), // 온보딩 페이지
      },
    );
  }
}
