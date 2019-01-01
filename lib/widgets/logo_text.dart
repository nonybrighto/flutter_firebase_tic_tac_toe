import 'package:flutter/material.dart';

class LogoText extends StatelessWidget {

  final double fontSize;
  LogoText({this.fontSize:50.0});

  @override
  Widget build(BuildContext context) {
    return Text('Tic Tac Toe', style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold
    ),);
  }
}