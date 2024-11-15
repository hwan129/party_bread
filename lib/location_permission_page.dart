import 'package:flutter/material.dart';

class LocationPermissionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Permission')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/onboarding');
          },
          child: Text('Allow Location Access'),
        ),
      ),
    );
  }
}
