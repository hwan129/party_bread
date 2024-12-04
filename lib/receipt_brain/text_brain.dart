import 'dart:math';
import 'dart:ui';

class TextBrain {
  //needs to take in list of lines of text

  TextBrain({
    required this.textLines,
  });

  final List<String> textLines;

  //needs to parse through the text to split into word list and cost list
  List<String> wordList = [];
  List<String> costList = [];
  List<String> itemList = [];

  //need to use regular expressions to differentiate between money, tax, tip, pretax or total, item names, item quantities
  // RegExp isMoney = RegExp(r'([0-9]{1,3}\,[0-9][0-9])');
  RegExp isMoney = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)');
  RegExp isTax = RegExp(r'([Tt][Aa][Xx])');
  // RegExp isTip = RegExp(r'([Tt][Ii][Pp])');
  RegExp totalOrSub = RegExp(r'([Tt][Oo][Tt][Aa][Ll])');
  RegExp hasQty = RegExp(r'([0-9]{1-3}\s|[0-9]{1,3})');

  //find these values
  num total = 0;
  num tax = 0;
  num sub = 0;

  dynamic parseText(List textLines) {
    //break into costs vs words
    for (int i = 0; i < textLines.length; i++) {
      if (isMoney.hasMatch(textLines[i])) {
        costList.add(textLines[i]);
      } else {
        wordList.add(textLines[i]);
      }
    }
  }

  List showWords() {
    return wordList;
  }

  String findTotal() {
    //can search for the largest number to find the total value, then remove that line from the list
    int indexToRemove = 0;

    for (int i = 0; i < costList.length; i++) {
      // num foundPrice = num.parse(isMoney.stringMatch(costList[i])!);
      num foundPrice = _parseMoney(costList[i]);
      //have to use regex stringMatch to remove any possible letters attached to costs
      if (foundPrice > total) {
        total = foundPrice;
        indexToRemove = i;
      }
    }

    //find total and/or subtotal in words list
    for (int i = 0; i < wordList.length; i++) {
      if (totalOrSub.hasMatch(wordList[i])) {
        //if word has total in it, remove it
        wordList.removeAt(i);
      }
    }
    costList.removeAt(indexToRemove);
    return total.toStringAsFixed(2).toString();
  }

  String findTax() {
    for (int i = 0; i < wordList.length; i++) {
      if (isTax.hasMatch(wordList[i])) {
        //if word has tax in it, remove it
        wordList.removeAt(i);
        //kind of flawed/not going to work for ever receipt, but assuming tax is the last item now
        // tax = num.parse(costList[costList.length - 1]);
        tax = _parseMoney(costList[costList.length - 1]);
        costList.removeLast();
      }
    }
    return tax.toStringAsFixed(2).toString();
  }

  String findSub() {
    //find subtotal by subtracting tax from total; search cost list for equal value and remove if found
    sub = total - tax;
    for (int i = 0; i < costList.length; i++) {
      if (num.parse(costList[i]) == sub) {
        costList.removeAt(i);
      }
    }
    return sub.toStringAsFixed(2).toString();
  }

  List showPrices() {
    return costList;
  }

  List getItems() {
    for (int i = 0; i < wordList.length; i++) {
      if (hasQty.hasMatch(wordList[i])) {
        itemList.add(wordList[i]);
      }
    }
    return itemList;
  }

  num _parseMoney(String money) {
    // 쉼표와 달러 기호 제거, 숫자만 남김
    money = money.replaceAll(',', '').replaceAll('\$', '');
    return num.parse(money);
  }
}