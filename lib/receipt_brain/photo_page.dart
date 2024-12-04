import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:async';
import 'compute_button.dart';
import 'text_brain.dart';

class PhotoPage extends StatefulWidget {
  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  // late String result;
  File? _image;
  InputImage? inputImage;
  final picker = ImagePicker();
  late String recognizedText;
  late String textBlock;
  late String textLine;
  late String textWord;
  List<String> lineList = [];

  //function picks image from gallery and displays on photo page
  Future pickImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        inputImage = InputImage.fromFilePath(pickedFile.path);
        imageToText(inputImage);
      } else {
        print('No image selected.');
      }
    });
  }

  //function triggers camera to take picture and then displays photo page
  Future captureImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        inputImage = InputImage.fromFilePath(pickedFile.path);
        imageToText(inputImage);
      } else {
        print('No image selected.');
      }
    });
  }

  Future imageToText(inputImage) async {
    // result = '';
    lineList = [];

    // final textDetector = GoogleMlKit.vision.textDetector();
    final textDetector = TextRecognizer();
    final RecognizedText recognizedText = await textDetector.processImage(inputImage);

    setState(() {
      String text = recognizedText.text;
      for (TextBlock block in recognizedText.blocks) {
        //blocks (blocks of text/sections)
        final String text = block.text;
        for (TextLine line in block.lines) {
          //lines - makes the most sense as the strings to parse through
          lineList.add(line.text);
          // for (TextElement element in line.elements) {
          //words
          // result += element.text + " ";
          // }
        }
      }
      // result += "\n\n";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Hacker'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              height: 550,
              child: Center(
                child: SingleChildScrollView(
                  child: _image == null
                      ? Text('Upload receipt')
                      : Image.file(_image!),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FloatingActionButton(
                onPressed: () {
                  print('Pick Image');
                  pickImageFromGallery();
                },
                child: Icon(Icons.attach_file),
              ),
              FloatingActionButton(
                onPressed: () {
                  print('Take a photo');
                  captureImageFromCamera();
                },
                child: Icon(Icons.add_a_photo),
              ),
            ],
          ),
          ComputeButton(
            onTap: () {
              TextBrain parse = TextBrain(
                textLines: lineList,
                // inputImage: inputImage,
              );
              Navigator.pushNamed(context, '/text', arguments: {
                'parse': parse.parseText(lineList),
                'total': parse.findTotal(),
                'tax': parse.findTax(),
                'sub': parse.findSub(),
                // 'words': parse.showWords(),
                // 'prices': parse.showPrices(),
                // 'items': parse.getItems(),
              });
            },
            buttonTitle: 'TEXTIFY!',
          ),
        ],
      ),
    );
  }
}

// <div>Icons made by <a href="https://www.freepik.com" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>