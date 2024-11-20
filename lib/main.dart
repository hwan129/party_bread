import 'package:flutter/material.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'location_permission_page.dart';
import 'onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'home.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
<<<<<<< Updated upstream
      initialRoute: '/', // ���� ������ ����
      routes: {
        '/': (context) => SplashPage(), // ���÷��� ������
        '/Login': (context) => LoginPage(), // �α��� ������
        '/signupEmail': (context) => SignupEmailPage(), // ȸ������ - �̸��� �Է� ������
        '/signupPhone': (context) => SignupPhonePage(), // ȸ������ - ��ȭ��ȣ �Է� ������
        '/signupName': (context) => SignupNamePage(), // ȸ������ - �̸� �Է� ������
        '/signupNickname': (context) => SignupNicknamePage(), // ȸ������ - �г��� �Է� ������
        '/locationPermission': (context) => LocationPermissionPage(), // ��ġ ���� Ȯ�� ������
        '/onboarding': (context) => OnboardingPage(), // �º��� ������
=======
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/locationPermission': (context) => LocationPermissionPage(), 
        '/onboarding': (context) => OnboardingPage(),
        '/home': (context) => HomePage(),
>>>>>>> Stashed changes
      },
    );
  }
}
