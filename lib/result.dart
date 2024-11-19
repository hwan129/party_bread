// 카테고리, 검색 결과 페이지
import 'package:flutter/material.dart';

class ResultPage extends StatefulWidget {
  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Result")),
      body: Column(
        children: [
          Column(
            children: [
              Text("원하시는 팟빵이 없으신가?"),
              Text("만들자!"),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/add');
                },
                child: const Text('반죽하러 가기'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
