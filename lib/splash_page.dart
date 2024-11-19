import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/Login');
    });
    return Scaffold(
      body: Center(child: Text('Splash Page', style: TextStyle(fontSize: 24))),
    );
  }
}
