// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
//
// import 'receipt_brain/text_brain.dart';
// import 'receipt_brain/compute.dart';
//
// class ReceiptPage extends StatefulWidget {
//   @override
//   _ReceiptState createState() => _ReceiptState();
// }
//
// class _ReceiptState extends State<ReceiptPage> {
//   String parsedtext = '';
//   String imagePath = '';
//   List<String> lineList = [];
//
//   Future _getFromGallery() async{
//     lineList = [];
//
//     final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (pickedFile == null) return;
//
//     // OCRAPI 에서 제공하는 이미지 형식으로 변환
//     var bytes = File(pickedFile.path.toString()).readAsBytesSync();
//     String img64 = base64Encode(bytes);
//
//     // url로 이미지 전송
//     var url = 'https://api.ocr.space/parse/image';
//     // 한국어 텍스트 인식을 위한..
//     var payload = {"base64Image": "data:image/jpg;base64,${img64.toString()}","language" :"kor", "isTable": "true"};
//     var header = {"apikey" :"K88223739188957"};
//
//     var post = await http.post(Uri.parse(url),body: payload,headers: header);
//     var result = jsonDecode(post.body);
//     setState(() {
//       parsedtext = result['ParsedResults'][0]['ParsedText'];
//       imagePath = pickedFile.path;
//
//       lineList = parsedtext.split('\n').map((line) => line.trim()).toList();
//     });
//
//     _showModal(parsedtext);
//   }
//
//   void _showModal(String result) {
//     showDialog(context: context, builder: (BuildContext context) {
//       return AlertDialog(title: Text('영수증 분석 결과'), content: SingleChildScrollView(
//         child: Text(result),
//       ),
//         actions: [
//           TextButton(onPressed: () {
//             Navigator.of(context).pop();
//           },
//             child: Text('닫기'),),
//         ],
//       );
//     },);
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
//             SizedBox(height: 20,),
//             ElevatedButton(onPressed: _getFromGallery, child: Text('영수증 사진 찾기'),),
//             // Text(parsedtext),
//             ComputeButton(
//               onTap: () {
//                 TextBrain parse = TextBrain(
//                   textLines: lineList,
//                   // inputImage: inputImage,
//                 );
//                 Navigator.pushNamed(context, '/text', arguments: {
//                   'parse': parse.parseText(lineList),
//                   'total': parse.findTotal(),
//                   'tax': parse.findTax(),
//                   'sub': parse.findSub(),
//                   'words': parse.showWords(),
//                   'prices': parse.showPrices(),
//                   'items': parse.getItems(),
//                 });
//               },
//               buttonTitle: '영수증 분석하기',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
//
//
