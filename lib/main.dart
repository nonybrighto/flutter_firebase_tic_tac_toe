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
        scaffoldBackgroundColor: Color(0XFF212845),
        brightness: Brightness.dark,
        primarySwatch: Colors.yellow,
      ),
      home:MenuPage(),
    );
  }
}