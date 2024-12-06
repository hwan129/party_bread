import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class Receipt extends StatefulWidget {
  @override
  _ReceiptState createState() => _ReceiptState();
}

// 그림 판
class _Painter extends CustomPainter {
  final List<Offset?> points;
  _Painter(this.points);

  // 펜 속성과.. 드래그하고 지나간 부분에 색칠하기
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Painter oldDelegate) => true;
}

class _ReceiptState extends State<Receipt> {
  File? _image;
  String? _totalAmount;
  String text = "";
  final picker = ImagePicker();
  List<Offset?> _points = [];
  GlobalKey _canvasKey = GlobalKey();
  bool _isZoomed = false;
  double _scale = 1.0;
  int peopleCount = 1;

  // 영수증 이미지 갤러리에서 가져오기
  Future<void> _gallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _points.clear();
      });
      _processImage(File(pickedFile.path));
    }
  }

  // 영수증 이미지 사진 찍기
  Future<void> _takePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _points.clear();
      });
      _processImage(File(pickedFile.path));
    }
  }

  // 영수증 분석
  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);

    List<String> extractedAmounts = [];
    RegExp regExp = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');

    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        if (regExp.hasMatch(line.text)) {
          extractedAmounts.add(regExp.firstMatch(line.text)?.group(0) ?? '');
        }
      }
    }

    // 읽어들인 가격들 중 천원 이상인 것만 저장
    String? validAmount;
    for (var amount in extractedAmounts) {
      final totalAmount = double.tryParse(amount.replaceAll(',', '').replaceAll(RegExp(r'[^\d.]'), '')) ?? 0;

      if (totalAmount >= 1000) {
        validAmount = amount;
        break;
      }
    }

    setState(() {
      _totalAmount = validAmount;
      text = recognizedText.text;
    });

    textRecognizer.close();
  }

  // 정산 인원 조정을 위한 버튼
  void _increasePeople() {
    setState(() {
      peopleCount++;
    });
  }

  void _decreasePeople() {
    if (peopleCount > 1) {
      setState(() {
        peopleCount--;
      });
    }
  }

  // 그림 전체 삭제
  void _clearDrawing() {
    setState(() {
      _points.clear();
    });
  }

  // 그림 그린 이미지 저장
  Future<ui.Image?> _captureCanvas() async {
    RenderRepaintBoundary boundary =
    _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    return await boundary.toImage(pixelRatio: 2.0);
  }

  Future<void> _saveDataToFirebase(String formattedAmount, ui.Image? capturedImage) async {
    // try {
      String? imageUrl;

      // 이미지 저장
      if (capturedImage != null) {
        final byteData = await capturedImage.toByteData(format: ui.ImageByteFormat.png);
        final Uint8List imageData = byteData!.buffer.asUint8List();

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('receipts/${DateTime.now().millisecondsSinceEpoch}.png');
        await storageRef.putData(imageData);
        imageUrl = await storageRef.getDownloadURL();
      }

      // 데이터 저장
      await FirebaseFirestore.instance.collection('receipts').add({
        'totalAmount': _totalAmount,
        'peopleCount': peopleCount,
        'perPersonAmount': formattedAmount,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

    // } catch (e) {
    //   print('Error saving data: $e');
    // }
  }

  // 선택한 이미지 화면에 보여주는 부분
  Widget _buildImageCanvas() {
    return _image == null
        ? const Center(child: Text("이미지를 선택하세요."))
        : RepaintBoundary(
      key: _canvasKey,
      child: Stack(
        children: [
          Center(
            child: Transform.scale(
              scale: _scale,
              child: Image.file(_image!),
            ),
          ),
          // Positioned(
          //   top: 10,
          //   right: 10,
          //   child: IconButton(
          //     icon: Icon(_isZoomed ? Icons.zoom_out : Icons.zoom_in),
          //     color: Colors.white,
          //     onPressed: () {
          //       setState(() {
          //         _isZoomed = !_isZoomed;
          //         _scale = _isZoomed ? 2.0 : 1.0;
          //       });
          //     },
          //   ),
          // ),

          // 펜 기능
          GestureDetector(
            // 그리기 시작
            onPanUpdate: (details) {
              setState(() {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset point = box.globalToLocal(details.localPosition);
                _points.add(point);
              });
            },
            // 그리기 끝
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: CustomPaint(
              painter: _Painter(_points),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('펜을 사용해 개인 정보를 지워주세요', style: TextStyle(fontSize: 18)),
                TextButton(onPressed: _clearDrawing, child: Text('전체 삭제')),
              ],
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: _decreasePeople, icon: Icon(Icons.remove)),
                Text('$peopleCount 명', style: TextStyle(fontSize: 20)),
                IconButton(onPressed: _increasePeople, icon: Icon(Icons.add)),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                if (_totalAmount != null) {
                  final ui.Image? capturedImage = await _captureCanvas();
                  final total = double.tryParse(
                      _totalAmount!.replaceAll(RegExp(r'[^\d.]'), '')) ??
                      0;
                  final perPerson = total / peopleCount;

                  final formatter = NumberFormat('#,###');
                  final formattedAmount = formatter.format(perPerson);

                  // 모달
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('정산 결과'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (capturedImage != null)
                            SizedBox(
                              width: 300,
                              height: 300,
                              child: RawImage(image: capturedImage),
                            ),
                          Text('총 금액 $_totalAmount 원', style: TextStyle(fontSize: 20)),
                          Text('정산할 인원 $peopleCount 명', style: TextStyle(fontSize: 20)),
                          Text('1인당 $formattedAmount 원', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('닫기'),
                        ),
                        TextButton(
                          onPressed:() async {
                            await _saveDataToFirebase(
                                formattedAmount, capturedImage);
                            Navigator.of(ctx).pushReplacementNamed('/chatting');
                          },
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
