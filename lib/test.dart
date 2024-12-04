import 'dart:typed_data';  // Uint8List 사용을 위한 임포트
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;

class ReceiptPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Receipt(),
    );
  }
}

class Receipt extends StatefulWidget {
  @override
  _ReceiptState createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  String resultText = '사진을 업로드하세요.';
  bool isLoading = false;
  img.Image? _image;
  List<String> redactedTexts = [];  // 민감한 정보가 덮여진 텍스트 목록

  // OCR을 통해 이미지에서 텍스트 추출
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close(); // 리소스 해제
    return recognizedText.text;
  }

  // 민감한 데이터를 필터링하는 함수
  String filterSensitiveData(String text) {
    final namePattern = RegExp(r'[가-힣]{2,4}\s[가-힣]{2,4}');
    final phonePattern = RegExp(r'\d{2,3}-\d{3,4}-\d{4}');
    final addressPattern = RegExp(r'(\w*시|\w*도|\w*구|\w*동|\w*로|\w*길)');

    text = text.replaceAll(namePattern, '[REDACTED]');
    text = text.replaceAll(phonePattern, '[REDACTED]');
    text = text.replaceAll(addressPattern, '[REDACTED]');

    return text;
  }

  // 가격 정보 추출
  String extractPrice(String text) {
    final pricePattern = RegExp(r'(총액|합계|가격):?\s?(\d{1,3}(,\d{3})*(\.\d{2})?)');
    final match = pricePattern.firstMatch(text);

    if (match != null) {
      return match.group(2) ?? '가격 정보 없음';
    } else {
      return '가격 정보 없음';
    }
  }

  // 민감한 텍스트 영역을 지우고, 해당 텍스트를 resultText에 저장하기
  void _eraseTextArea(List<TextBlock> textBlocks) {
    List<String> detectedTexts = [];  // 덮은 텍스트를 저장할 리스트

    for (var block in textBlocks) {
      for (var line in block.lines) {
        final text = line.text;
        print(text);
        // 전화번호, 주소 등 민감한 정보를 포함하는 텍스트가 있을 경우
        if (RegExp(r'\d{2,3}-\d{3,4}-\d{4}').hasMatch(text) ||
            RegExp(r'\w*시|\w*구|\w*동|\w*로|\w*길').hasMatch(text)) {
          final rect = line.boundingBox;

          if (rect != null && _image != null) {
            // 덮을 영역의 텍스트를 기록
            detectedTexts.add(text);  // 민감한 정보 텍스트 추가

            // 흰색으로 덮기
            for (int y = rect.top.toInt(); y < rect.top + rect.height; y++) {
              for (int x = rect.left.toInt(); x < rect.left + rect.width; x++) {
                _image!.setPixel(x, y, img.ColorFloat16(0xffffff));
              }
            }
          }
        }
      }
    }

    // 덮은 텍스트를 resultText에 표시
    setState(() {
      if (detectedTexts.isEmpty) {
        resultText = '처리된 영역 없음';
      } else {
        resultText = '민감한 정보가 덮인 텍스트:\n' + detectedTexts.join('\n');
      }
    });
  }

  // 이미지 선택 및 처리
  Future<void> pickAndProcessImage() async {
    setState(() {
      isLoading = true;
      resultText = '처리 중입니다...';
    });

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final extractedText = await extractTextFromImage(pickedFile.path);
        final filteredText = filterSensitiveData(extractedText);
        final price = extractPrice(filteredText);

        setState(() {
          resultText = '가격 정보: $price';
        });

        // 이미지 리사이즈 없이 원본 사이즈로 가져오기
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _image = img.decodeImage(Uint8List.fromList(imageBytes));
        });

        // 원본 크기 그대로 표시
        setState(() {});

        final textRecognizer = GoogleMlKit.vision.textRecognizer();
        final inputImage = InputImage.fromFilePath(pickedFile.path);
        final recognizedText = await textRecognizer.processImage(inputImage);


        // 민감한 정보가 포함된 텍스트 영역을 지우기
        _eraseTextArea(recognizedText.blocks);

        setState(() {});
      } else {
        setState(() {
          resultText = '이미지가 선택되지 않았습니다.';
        });
      }
    } catch (e) {
      setState(() {
        resultText = '오류가 발생했습니다: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('영수증 텍스트 인식'),
      ),
      body: SingleChildScrollView( // SingleChildScrollView로 감쌈
        child: Center(
          child: isLoading
              ? CircularProgressIndicator()
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? Text(
                resultText,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              )
                  : Image.memory(Uint8List.fromList(img.encodeJpg(_image!))),  // 원본 이미지 그대로 표시
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickAndProcessImage,
                child: Text('영수증 업로드'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(ReceiptPage());
}
