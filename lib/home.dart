import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home"), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.person, semanticLabel: 'profile'),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
      ]),
    );
  }
}
