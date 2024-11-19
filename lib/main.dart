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
      initialRoute: '/Login', // ���� ������ ����
      routes: {
        '/Login': (context) => LoginPage(), // �α��� ������
        '/signupEmail': (context) => SignupEmailPage(), // ȸ������ - �̸��� �Է� ������
        '/signupPhone': (context) => SignupPhonePage(), // ȸ������ - ��ȭ��ȣ �Է� ������
        '/signupName': (context) => SignupNamePage(), // ȸ������ - �̸� �Է� ������
        '/signupNickname': (context) =>
            SignupNicknamePage(), // ȸ������ - �г��� �Է� ������
        '/locationPermission': (context) =>
            LocationPermissionPage(), // ��ġ ���� Ȯ�� ������
        '/onboarding': (context) => OnboardingPage(), // �º��� ������
      },
    );
  }
}
