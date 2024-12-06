import 'package:flutter/material.dart';
import 'login_page.dart';
import 'location_permission_page.dart';
import 'onboarding_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'home.dart';
import 'profile.dart';
import 'result.dart';
import 'add.dart';
import 'signup_page.dart';
import 'receipt.dart';
import 'chat_page.dart';
import 'provider.dart';
import 'maps/getlocation.dart';
import 'sign_in_email.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => GeoProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
          primarySwatch: Colors.brown, // 주요
          scaffoldBackgroundColor: Colors.white, // 배경
          appBarTheme: AppBarTheme(
            // appbar style
            backgroundColor: Color(0xFF574142),
            foregroundColor: Colors.white,
          ),
          textButtonTheme: TextButtonThemeData(
            // textbutton
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFE5D6D6),
              foregroundColor: Colors.black,
            ),
          ),
          textTheme: TextTheme(
            // 기본 text
            bodyLarge: TextStyle(color: Color(0xFF574142)),
            bodyMedium: TextStyle(color: Color(0xFF574142)),
            bodySmall: TextStyle(color: Color(0xFF574142)),
          ),
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.brown,
          )),

      initialRoute: '/login', // 시작 페이지 설정
      routes: {
        '/home': (context) => HomePage(), // 메인 페이지
        '/login': (context) => LoginPage(), // 로그인 페이지
        '/result': (context) => ResultPage(), // 카테고리, 검색 결과 페이지
        '/profile': (context) => ProfilePage(), // 프로필 페이지
        '/add': (context) => AddPage(),
        '/receipt': (context) => Receipt(),
        '/signup': (context) => SignupPage(),
        '/sign_in_email': (context) => SignInEmailPage(),
        '/locationPermission': (context) =>
            LocationPermissionPage(), // 위치 정보 확인 페이지
        '/onboarding': (context) => OnboardingPage(), // 온보딩 페이지
        '/getlocation': (context) => GetLocation(), // 지도에서 위치 가져오는 페이지
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chatting') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatRoomPage(
              roomId: args['roomId'], // 전달받은 roomId를 사용
            ),
          );
        }
        return null; // 정의되지 않은 경로 처리
      },
    );
  }
}
