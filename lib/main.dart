import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/menu_page.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Color(0XFF212845),
        accentColor: Color(0XFFF8D320),
        scaffoldBackgroundColor: Color(0XFF212845),
        primarySwatch: Colors.yellow,
        buttonColor: Color(0XFFF8D320),
        textTheme:  TextTheme(
          body1: TextStyle(
            color: Colors.white
          ),
          button: TextStyle(
            color: Colors.green, // This is not working.
            fontSize: 30.0,
            fontWeight: FontWeight.bold
          )
        )
      ),
      home:MenuPage(),
    );
  }
}