import 'package:flutter/material.dart';

class SignupNicknamePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up - Nickname')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter your Nickname'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Nickname'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/Login');
              },
              child: Text('Complete Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
