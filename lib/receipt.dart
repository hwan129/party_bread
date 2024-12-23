import 'package:firebase_auth/firebase_auth.dart';
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
  final String roomId;

  Receipt({required this.roomId});

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
      final totalAmount = double.tryParse(
              amount.replaceAll(',', '').replaceAll(RegExp(r'[^\d.]'), '')) ??
          0;

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

  Future<void> _saveDataToFirebase(
      String formattedAmount, ui.Image? capturedImage) async {
    // try {
    String? imageUrl;

    // 이미지 저장
    if (capturedImage != null) {
      final byteData =
          await capturedImage.toByteData(format: ui.ImageByteFormat.png);
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

    _sendReceiptMessage(formattedAmount, imageUrl);
    // } catch (e) {
    //   print('Error saving data: $e');
    // }
  }

  Future<void> _sendReceiptMessage(
      String formattedAmount, String? imageUrl) async {
    final message = {
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'nickname': '엔빵이',
      'message':
          '영수증 분석 결과\n총 금액 $_totalAmount 원\n총 $peopleCount 명\n인당 $formattedAmount 원',
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('messages')
        .add(message);
  }

  // 선택한 이미지 화면에 보여주는 부분
  Widget _buildImageCanvas() {
    return _image == null
        ? const Center(
            child: Text(
            "이미지를 선택해주세요.",
            style: TextStyle(fontSize: 20),
          ))
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

                // 이미지가 선택되었을 때만 펜 기능을 사용
                if (_image != null)
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
            if (_image != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('펜을 사용해 개인 정보를 지워주세요', style: TextStyle(fontSize: 18)),
                  TextButton(onPressed: _clearDrawing, child: Text('전체 삭제')),
                ],
              ),
            ],
            SizedBox(height: 10),
            Expanded(child: _buildImageCanvas()),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: _gallery,
                    icon: Icon(
                      Icons.attach_file,
                    )),
                IconButton(
                    onPressed: _takePhoto, icon: Icon(Icons.add_a_photo)),
              ],
            ),
            if (_totalAmount != null) ...[
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('총 금액 ', style: TextStyle(fontSize: 23)),
                  Text('$_totalAmount',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  Text(' 원', style: TextStyle(fontSize: 23)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('정산할 인원', style: TextStyle(fontSize: 23)),
                  IconButton(
                      onPressed: _decreasePeople, icon: Icon(Icons.remove)),
                  Text('$peopleCount 명',
                      style:
                          TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: _increasePeople, icon: Icon(Icons.add)),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF574142),
                  foregroundColor: Color(0xFFF5E0D3),
                  minimumSize: Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
                        title: Text('정산 결과',
                            style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF574142))),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (capturedImage != null)
                              SizedBox(
                                width: 300,
                                height: 300,
                                child: RawImage(image: capturedImage),
                              ),
                            SizedBox(height: 10),
                            Text(
                              '총 금액 $_totalAmount 원',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 1),
                            Text('정산할 인원 $peopleCount 명',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 1),
                            Text('1인당 $formattedAmount 원',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        actions: [
                          Column(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(
                                  '취소',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Color(0xFFF5E0D3)),
                                  foregroundColor: MaterialStateProperty.all(
                                      Color(0xFF574142)),
                                  minimumSize: MaterialStateProperty.all(
                                      Size(double.infinity, 50)),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              TextButton(
                                onPressed: () async {
                                  final docRef = await FirebaseFirestore
                                      .instance
                                      .collection('chatRooms')
                                      .doc(widget.roomId)
                                      .get();
                                  final docId = docRef.id;

                                  await _saveDataToFirebase(
                                      formattedAmount, capturedImage);
                                  Navigator.of(ctx).pushReplacementNamed(
                                    '/chatting',
                                    arguments: {'roomId': docId},
                                  );
                                },
                                child: Text(
                                  '확인',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all(
                                      Color(0xFF574142)),
                                  foregroundColor: MaterialStateProperty.all(
                                      Color(0xFFF5E0D3)),
                                  minimumSize: MaterialStateProperty.all(
                                      Size(double.infinity, 50)),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Text(
                  '정산하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
