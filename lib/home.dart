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
      body: Column(
        children: [
          Column(
            children: [
              Text("어떤 팟빵에 드갈래"),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result', arguments: 0,);
                    },
                    child: const Text('배달팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result', arguments: 1,);
                    },
                    child: const Text('택시팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result', arguments: 2,);
                    },
                    child: const Text('공구팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result', arguments: 3,);
                    },
                    child: const Text('기타팟빵'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
