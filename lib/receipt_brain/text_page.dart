import 'package:flutter/material.dart';

class TextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Map textArgs = ModalRoute.of(context)!.settings.arguments as Map;
    print('textArgs');
    print(textArgs);

    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Hacker'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: <Widget>[
                Text('Items'),
                for (var item in textArgs['items']) Text(item),
                SizedBox(
                  height: 10.0,
                ),
                Text('Subtotal'),
                Text('Tax'),
                Text('Total'),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Prices',
                ),
                for (var price in textArgs['prices']) Text(price),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  textArgs['sub'],
                ),
                Text(
                  textArgs['tax'],
                ),
                Text(
                  textArgs['total'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}