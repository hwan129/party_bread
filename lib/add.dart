// 카테고리, 검색 결과 페이지
import 'package:flutter/material.dart';

class AddPage extends StatefulWidget {
  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add")),
      body: Column(
        children: [
          Column(
            children: [
              Text("원하시는 팟빵이 없으신가?"),
              Text("만들자!"),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/result');
                },
                child: const Text('팟빵 굽기'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
