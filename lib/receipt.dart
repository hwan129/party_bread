// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
// import 'package:image_picker/image_picker.dart';
//
// class ReceiptPage extends StatefulWidget {
//   @override
//   _ReceiptPageState createState() => _ReceiptPageState();
// }
//
// class _ReceiptPageState extends State<ReceiptPage> {
//   String parsedtext = '';
//   String imagePath = '';
//
//   Future<void> _getFromGallery() async {
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (imagePath.isNotEmpty) {
//
//       setState(() {
//         imagePath = pickedFile.path;
//       });
//
//       await _processImage(pickedFile.path);
//     }
//   }
//   }
//
//   Future<void> _processImage(String imagePath) async {
//     final inputImage = InputImage.fromFilePath(imagePath);
//     final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
//
//     // try {
//     final recognizedText = await textRecognizer.processImage(inputImage);
//
//     setState(() {
//       parsedtext = recognizedText.text;
//     });
//
//     _showResultModal(parsedtext ?? "텍스트를 인식하지 못했습니다.");
//     // }
//     // finally {
//     //   textRecognizer.close(); // 리소스 해제
//     // }
//   }
//
//   void _showResultModal(String result) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('영수증 분석 결과'),
//           content: SingleChildScrollView(
//             child: Text(result),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('닫기'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('영수증 분석'),
//       ),
//       body: Center(
//         child: Column(
//           children: [
//             if (imagePath != null)
//               Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Image.file(
//                   File(imagePath!),
//                   height: 500,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _getFromGallery,
//               child: Text('영수증 사진 찾기'),
//             ),
//             SizedBox(height: 20),
//             if (parsedtext != null)
//               Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Text(
//                   '분석된 텍스트:\n$parsedtext',
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
