import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

class Receipt extends StatefulWidget {
  @override
  _ReceiptState createState() => _ReceiptState();
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter(this.points);

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
  bool shouldRepaint(_SignaturePainter oldDelegate) => true;
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

  Future<void> _gallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _points.clear(); // 그림판 초기화
      });
      _processImage(File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _points.clear(); // 그림판 초기화
      });
      _processImage(File(pickedFile.path));
    }
  }

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

  void _clearDrawing() {
    setState(() {
      _points.clear();
    });
  }

  Future<ui.Image?> _captureCanvas() async {
    RenderRepaintBoundary boundary =
    _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    return image;
  }

  Widget _buildImageCanvas() {
    return _image == null
        ? const Center(child: Text("이미지를 선택하세요."))
        : RepaintBoundary(
      key: _canvasKey,
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _scale = details.scale;
                });
              },
              onTap: () {
                setState(() {
                  _isZoomed = !_isZoomed;
                  _scale = _isZoomed ? 2.0 : 1.0; // 확대/축소 상태에 따라 scale 변경
                });
              },
              child: Transform.scale(
                scale: _scale,
                child: Image.file(_image!),
              ),
            ),
          ),
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset point = box.globalToLocal(details.localPosition);
                _points.add(point);
              });
            },
            onPanEnd: (details) {
              setState(() {
                _points.add(null);
              });
            },
            child: CustomPaint(
              painter: _SignaturePainter(_points),
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
                TextButton(onPressed: _clearDrawing, child: Text('삭제')),
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
                          Text('1인당 $formattedAmount 원', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('취소'),),
                            TextButton(onPressed: () => Navigator.of(ctx).popAndPushNamed('/chatting'), child: Text('확인'),),
                          ],
                        )
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

