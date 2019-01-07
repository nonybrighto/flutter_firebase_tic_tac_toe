import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/auth_page.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/game_board.dart';
import 'package:flutter_firebase_tic_tac_toe/high_score_board.dart';
import 'package:flutter_firebase_tic_tac_toe/users_board.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {


  UserBloc _userBloc;
  FirebaseMessaging _messaging = new FirebaseMessaging();

  @override
    void initState() {
      // TODO: implement initState
      super.initState();

    _messaging.configure(onLaunch: (Map<String, dynamic> message) {
      print(message);
    }, onMessage: (Map<String, dynamic> message) {

      print(message);
    }, onResume: (Map<String, dynamic> message) {
      //  print(message);
    });

    _messaging.getToken().then((token) {
      print('------------------');
      print(token);
      _userBloc.changeFcmToken(token);
    });



  }


  @override
  Widget build(BuildContext context) {

    _userBloc = BlocProvider.of(context).userBloc;
    return Scaffold(
      backgroundColor: Color(0XFF212845),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: -60.0,
            top: -75.0,
            child: _bigLetter('X'),
          ),
          Positioned(
            right: -100.0,
            bottom: -75.0,
            child: _bigLetter('O'),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                
                Text(
                  'Tic Tac Toe',
                  style: TextStyle(
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,),
                ),
                SizedBox(
                  height: 80.0,
                ),
                _menuButton('PLAY WITH COMPUTER', (){
                  Navigator.of(context).push(MaterialPageRoute(builder:(index)=> GameBoard()));
                }),
                _menuButton('PLAY WITH USER', 
                  (){
                  _userBloc.getUsers();
                  Navigator.of(context).push(MaterialPageRoute(builder:(index)=> UsersBoard()));
                }
                ),
                _menuButton('HIGH SCORE', (){
                   Navigator.of(context).push(MaterialPageRoute(builder:(index)=> HighScoreBoard()));
                }),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                  Text('Play with Others?', style: TextStyle(
                    fontSize: 18.0
                  ),),
                  FlatButton(child: Text('Sign In', style:  TextStyle(
                    fontSize: 18.0,
                    color: Colors.blue
                  ),), onPressed: (){
                   Navigator.of(context).push(MaterialPageRoute(builder:(index)=> AuthPage(false)));
                },)
                ],)
              ],
            ),
          )
        ],
      ),
    );
  }
}

_menuButton(String text, onPressed) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 40.0),
    child: SizedBox(
      width: 300.0,
      child: RaisedButton(
          color: Color(0XFFF8D320),
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Text(text, style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),),
          ), onPressed: onPressed),
    ),
  );
}

_bigLetter(String letter) {
  return Text(
    letter,
    style: TextStyle(
      color: Colors.black,
      fontSize: 350.0,
    ),
  );
}
