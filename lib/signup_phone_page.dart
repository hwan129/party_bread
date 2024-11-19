import 'package:flutter/material.dart';

class SignupPhonePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up - Phone')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter your Phone Number'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signupName');
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
