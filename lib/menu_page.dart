import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/auth_page.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/game_board.dart';
import 'package:flutter_firebase_tic_tac_toe/game_process_page.dart';
import 'package:flutter_firebase_tic_tac_toe/high_score_board.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:flutter_firebase_tic_tac_toe/users_board.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_firebase_tic_tac_toe/widgets/slide_button.dart';


class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  UserBloc _userBloc;
  GameBloc _gameBloc;
  FirebaseMessaging _messaging = new FirebaseMessaging();

  AnimationController _animationController;
  Animation<double> _bigLetterScale;
  List<Animation<double>> _menuButtonSlides;

  @override
  void initState() {
    super.initState();

    _animationController = new AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _bigLetterScale = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInCirc));

    _menuButtonSlides = [];
    for (int i = 0; i < 4; i++) {
      _menuButtonSlides.add(Tween<double>(begin: -1.0, end: 0.0).animate(
          CurvedAnimation(
              parent: _animationController,
              curve: Interval(i / 3, 1.0, curve: Curves.easeIn))));
    }

    _animationController.forward();

    _messaging.configure(onLaunch: (Map<String, dynamic> message) {
      print('ON LAUNCH ----------------------------');
      print(message);
    }, onMessage: (Map<String, dynamic> message) {
      String notificationType = message['data']['notificationType'];

      switch (notificationType) {
        case 'challenge':
          _showAcceptanceDialog(message['data']['senderId'],
              message['data']['senderName'], message['data']['senderFcmToken']);
          break;
        case 'started':
          _gameBloc.startServerGame(
              message['data']['player1Id'], message['data']['player2Id']);
          break;
        case 'replayGame':
          _gameBloc.changeAllowReplay(false);
          break;
        case 'rejected':
          _showGameRejectedDialog(message);
          break;
        case 'gameEnd':
          _gameBloc.clearProcessDetails();
          _showGameEndDialog(message);
          break;
        default:
          print('message');
          break;
      }
    }, onResume: (Map<String, dynamic> message) {
      // _showAcceptanceDialog(message);
      print('ON RESUME ----------------------------');
      print(message);
      String notificationType = message['notificationType'];
      switch (notificationType) {
        case 'challenge':
          _showAcceptanceDialog(message['senderId'], message['senderName'],
              message['senderFcmToken']);
          break;
        case 'started':
          _gameBloc.startServerGame(message['player1Id'], message['player2Id']);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => GameProcessPage()));
          break;
        case 'gameEnd':
          _gameBloc.clearProcessDetails();
          break;
      }
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
    _gameBloc = BlocProvider.of(context).gameBloc;
    return Scaffold(
      backgroundColor: Color(0XFF212845),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: -60.0,
            top: -75.0,
            child:  _bigLetter('X'),
          ),
          Positioned(
            right: -100.0,
            bottom: -75.0,
            child: _bigLetter('O'),
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 40.0,
                ),
                Text(
                  'Tic Tac Toe',
                  style: TextStyle(
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 40.0,
                ),
                StreamBuilder(
                  initialData: null,
                  stream: _userBloc.currentUser,
                  builder: (context, currentUserSnapshot) {
                    if (!currentUserSnapshot.hasData) {
                      return Container();
                    }
                    User currentUser = currentUserSnapshot.data;
                    return (currentUser.id != null)
                        ? Text('currentUser - ' + currentUser.name)
                        : Container();
                  },
                ),
                SizedBox(
                  height: 40.0,
                ),
                SlideButton(
                  text: 'PLAY WITH COMPUTER',
                  animation: _menuButtonSlides[0],
                  onPressed: () {
                    _gameBloc.startSingleDeviceGame(GameType.computer);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (index) => GameBoard()));
                  },
                ),
                SlideButton(
                  text: 'PLAY WITH FRIEND',
                  animation: _menuButtonSlides[1],
                  onPressed: () {
                    _gameBloc.startSingleDeviceGame(GameType.multi_device);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (index) => GameBoard()));
                  },
                ),
                SlideButton(
                  text: 'PLAY WITH USERS',
                  animation: _menuButtonSlides[2],
                  onPressed: () {
                    _userBloc.getUsers();
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (index) => UsersBoard()));
                  },
                ),
                SlideButton(
                  text: 'HIGH SCORE',
                  animation: _menuButtonSlides[3],
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (index) => HighScoreBoard()));
                  },
                ),
                StreamBuilder(
                  initialData: null,
                  stream: _userBloc.currentUser,
                  builder: (context, currentUserSnapshot) {
                    if (currentUserSnapshot.hasData &&
                        currentUserSnapshot.data.id != null) {
                      return FlatButton(
                        child: Text(
                          'Logout',
                          style: TextStyle(fontSize: 18.0, color: Colors.blue),
                        ),
                        onPressed: () {
                          _userBloc.logoutUser();
                        },
                      );
                    } else {
                      return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Play with Others?',
                              style: TextStyle(fontSize: 18.0),
                            ),
                            FlatButton(
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.blue),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (index) => AuthPage(false)));
                              },
                            )
                          ]);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _showGameEndDialog(Map<String, dynamic> message) async {
    Future.delayed(Duration.zero, () {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Game Ended!'),
              content: Text(message['notification']['body']), // get from server

              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MenuPage()));
                  },
                ),
              ],
            ),
      );
    });
  }

  _showGameRejectedDialog(Map<String, dynamic> message) async {
    Future.delayed(Duration.zero, () {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Game Rejected!'),
              content: Text(message['notification']['body']), // get from server

              actions: <Widget>[
                FlatButton(
                  child: Text('OK'),
                  onPressed: () async {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => MenuPage()));
                  },
                ),
              ],
            ),
      );
    });
  }

  _showAcceptanceDialog(String challengerId, String challengerName,
      String challengerFcmToken) async {

    Future.delayed(Duration.zero, () {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => StreamBuilder<User>(
          stream: _userBloc.currentUser,
          builder: (context, currentUserSnapshot){

            String senderId = currentUserSnapshot.data?.id;
            String senderName = currentUserSnapshot.data?.name;
            String senderFcmToken =currentUserSnapshot.data?.fcmToken;

            return AlertDialog(
              title: Text('Tic Tac Toe Challeenge'),
              content: Text(challengerName +
                  ' has Challenged you to a game of tic tac toe'),
              actions: <Widget>[
                FlatButton(
                  child: Text('ACCEPT'),
                  onPressed: () async {
                    _gameBloc.handleChallenge(
                        senderId,
                        senderName,
                        senderFcmToken,
                        challengerId,
                        challengerName,
                        challengerFcmToken,
                        ChallengeHandleType.accept);
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => GameProcessPage()));
                  },
                ),
                FlatButton(
                  child: Text('DECLINE'),
                  onPressed: () {
                    _gameBloc.handleChallenge(
                        senderId,
                        senderName,
                        senderFcmToken,
                        challengerId,
                        challengerName,
                        challengerFcmToken,
                        ChallengeHandleType.reject);
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },


        ),
      );
    });
  }

  _bigLetter(String letter) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
            scale: _bigLetterScale.value,
            child: Text(
              letter,
              style: TextStyle(
                color: Colors.black,
                fontSize: 350.0,
              ),
            ));
      },
    );
  }
}
