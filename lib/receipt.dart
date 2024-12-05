import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class Receipt extends StatefulWidget {
  @override
  _ReceiptState createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  File? _image;
  String? _totalAmount;
  String text = "";
  final _peopleController = TextEditingController();
  final picker = ImagePicker();

  // 갤러리 뒤지기
  Future<void> _gallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processImage(File(pickedFile.path));
    }
  }

  // 사진 찰칵
  Future<void> _takePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _processImage(File(pickedFile.path));
    }
  }

  // 이미지 분석
  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);

    List<String> extractedAmounts = []; // 추출한 텍스트 저장소
    RegExp regExp = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        if (regExp.hasMatch(line.text)) {
          extractedAmounts.add(regExp.firstMatch(line.text)?.group(0) ?? '');
        }
      }
    }

    // 천원 이상의 금액을 찾은 경우에만 저장
    String? validAmount;
    for (var amount in extractedAmounts) {
      final totalAmount = double.tryParse(amount.replaceAll(',', '').replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

      if (totalAmount >= 1000) {
        validAmount = amount;
        break;
      }
    }

    setState(() {
      if (validAmount != null) {
        _totalAmount = validAmount;
      } else {
        _totalAmount = null;
      }
      text = recognizedText.text;
    });

    textRecognizer.close();
  }

  @override
  void dispose() {
    _peopleController.dispose();
    super.dispose();
  }

  // 그림판
  Widget _buildImageCanvas() {
    return _image == null
        ? const Center(child: Text("이미지를 선택하세요."))
        : GestureDetector(
      onPanUpdate: (details) {
        // 그림판 기능 구현 필요 시 추가
      },
      child: Image.file(_image!),
    );
  }

  // 정산 인원 설정하는 버튼 기능
  int peopleCount = 1;

  void _increasePeople() { // 플러스 버튼
    setState(() {
      peopleCount++;
    });
  }

  void _decreasePeople() { // 마이너스
    if (peopleCount > 1) {
      setState(() {
        peopleCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('정산하기')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(child: _buildImageCanvas()),
            // 영수증 사진 고르기 or 사진 찍기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _gallery, icon: Icon(Icons.attach_file)),
                IconButton(onPressed: _takePhoto, icon: Icon(Icons.add_a_photo)),
              ],
            ),
            if (_totalAmount != null)
              Text('총 금액: $_totalAmount 원', style: TextStyle(fontSize: 24)),
            Text('정산할 인원', style: TextStyle(fontSize: 24)),
            // 정산할 인원수 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _decreasePeople,
                  icon: Icon(Icons.remove),
                ),
                Text('$peopleCount 명', style: TextStyle(fontSize: 20)),
                IconButton(
                  onPressed: _increasePeople,
                  icon: Icon(Icons.add),
                ),
              ],
            ),
            // 정산하기 버튼 -> 인당 얼마씩인지 + 영수증에 그림 그리기
            ElevatedButton(
              onPressed: () {
                if (_totalAmount != null && _peopleController.text.isNotEmpty) {
                  final total = double.tryParse(
                      _totalAmount!.replaceAll(RegExp(r'[^\d.]'), '')) ??
                      0;
                  final perPerson = (total / peopleCount);

                  // 정산한 금액 천 단위로 콤마 찍어주기
                  final formatter = NumberFormat('#,###');
                  final formattedAmount = formatter.format(perPerson);

                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('정산 결과'),
                      content: Text(
                        '1인당 $formattedAmount 원',
                        style: TextStyle(fontSize: 18),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('확인'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: Text('정산하기'),
            ),
          ],
        ),
      ),
    );
  }
}
