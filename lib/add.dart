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
              Text("팟빵 종류를 선택해주세요"),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result');
                    },
                    child: const Text('배달팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result');
                    },
                    child: const Text('택시팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result');
                    },
                    child: const Text('공구팟빵'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/result');
                    },
                    child: const Text('기타팟빵'),
                  ),
                ],
              ),
              Text("무엇을 먹을건가요?"),
              Text("상세하게 적어줘"),
              TextFormField(
                // controller: _controllerName,
                decoration: const InputDecoration(
                  hintText: '적어요!',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text("더 자세히 적어줘"),
              Text("시간"),
              TextFormField(
                // controller: _controllerName,
                decoration: const InputDecoration(
                  hintText: '시간',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              Text("장소"),
              TextFormField(
                // controller: _controllerName,
                decoration: const InputDecoration(
                  hintText: '장소',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              Text("인원"),
              TextFormField(
                // controller: _controllerName,
                decoration: const InputDecoration(
                  hintText: '인원',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              Text("추가 사항"),
              TextFormField(
                // controller: _controllerName,
                decoration: const InputDecoration(
                  hintText: '추가 사항',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a product name';
                  }
                  return null;
                },
              ),
              TextButton(
                onPressed: () {
                  // Navigator.pushNamed(context, '/result');
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
