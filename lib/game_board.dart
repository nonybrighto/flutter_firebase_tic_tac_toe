import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/menu_page.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';

class GameBoard extends StatefulWidget {
  GameBoard({Key key}) : super(key: key);

  @override
  _GameBoardState createState() => new _GameBoardState();
}

class _GameBoardState extends State<GameBoard> with TickerProviderStateMixin {
  GameBloc _gameBloc;

   AnimationController _opacityController;
   AnimationController _boxController;
   Animation<double> _opacity;
   Animation<double> _boxRotate;
   Animation<double> _boxScale;


   @override
  void initState() {
    super.initState();
     _opacityController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
     _boxController = new AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
     _opacity = new CurvedAnimation(parent: _opacityController, curve: Curves.easeIn);
     _boxRotate = Tween<double>(begin: 0, end: 360).animate(_boxController);
     _boxScale = Tween<double>(begin: 0, end: 1.0).animate(_boxController);

     _opacityController.addStatusListener((status){
          if(status ==AnimationStatus.completed){
            _boxController.forward();
          }
     });

     _opacityController.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _opacityController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _gameBloc = BlocProvider.of(context).gameBloc;
    return WillPopScope(
        onWillPop: _cancelGameDialog,
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
        child: SingleChildScrollView(
                  child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  StreamBuilder<Player>(
                    initialData: null,
                    stream: _gameBloc.player1,
                    builder: (context, player1Snapshot) {
                      final player1 = player1Snapshot.data;
                      return (player1 != null) ?_scoreBox(
                          player1.user.name, player1.user.name, player1.score) : Container();
                    },
                  ),
                  Text(
                    'VS',
                    style: TextStyle(fontSize: 45.0),
                  ),
                  StreamBuilder<Player>(
                    initialData: null,
                    stream: _gameBloc.player2,
                    builder: (context, player2Snapshot) {
                      final player2 = player2Snapshot.data;
                      return (player2 != null) ? _scoreBox(
                          player2.user.name, player2.user.name, player2.score): Container();
                    },
                  ),
                ],
              ),
              StreamBuilder<String>(
                initialData: 'Tic Tac Toe',
                stream: _gameBloc.gameMessage,
                builder: (context, gameMessageSnapshot) {
                  return Text(
                    gameMessageSnapshot.data,
                    style: TextStyle(
                        color: Theme.of(context).accentColor, fontSize: 20.0),
                  );
                },
              ),

              SizedBox(height: 40.0),
           
               Container(
                  child: Center(child: 
                     AnimatedBuilder(
                       animation: _boxController,
                       builder: (context, child){

                         return  Transform.rotate(
                        angle: _boxRotate.value * 3.14/180,
                        child: Transform.scale(
                          scale: _boxScale.value,
                          child: _playBox(),
                        ),
                      );
                       },
                     )
                  ),
                ),

              SizedBox(height: 10.0),
              
              StreamBuilder<bool>(
                initialData: false,
                stream: _gameBloc.gameOver,
                builder: (context, allowReplaySnapshot){

                  return (allowReplaySnapshot.data)?_menuButton('PLAY AGAIN', () {
                    _gameBloc.replayCurrentGame();
                  }): Container();
                },
              )
            ],
          ),
        ),
      ),
    ),

    );
  }

  Future<bool> _cancelGameDialog(){
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(

          title: Text('Cancel Game'),
          content: Text('Do you wish to cancel the current game?'),
          actions: <Widget>[
            FlatButton(
                child: Text('YES'),
                onPressed: () async{
                      _gameBloc.cancelGame();
                     Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => MenuPage()), (route) => false);
                },
              ),
              FlatButton(
                child: Text('NO'),
                onPressed: () async{
                     Navigator.of(context).pop(false);
                },
              ),
          ],
      )
    )??false;
  }

  _playBox() {
    Color borderColor = Color(0xFF206efe);
    double borderWidth = 4.0;
    Border lrBorder = Border(
        left: BorderSide(color: borderColor, width: borderWidth),
        right: BorderSide(color: borderColor, width: borderWidth));
    Border tbBorder = Border(
        top: BorderSide(color: borderColor, width: borderWidth),
        bottom: BorderSide(color: borderColor, width: borderWidth));
    Border centreBorder = Border.merge(lrBorder, tbBorder);
    return StreamBuilder<List<GamePiece>>(
      initialData: List.generate(9, (index) => GamePiece(piece:'', pieceType:PieceType.normal)),
      stream: _gameBloc.currentBoard,
      builder: (context, currentBoardSnapshot) {
        List<GamePiece> currentBoard = currentBoardSnapshot.data;
        
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _drawBoardTile(currentBoard[0], 0),
                _drawBoardTile(currentBoard[1], 1, border: lrBorder),
                _drawBoardTile(currentBoard[2], 2),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _drawBoardTile(currentBoard[3], 3, border: tbBorder),
                _drawBoardTile(currentBoard[4], 4, border: centreBorder),
                _drawBoardTile(currentBoard[5], 5, border: tbBorder),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _drawBoardTile(currentBoard[6], 6),
                _drawBoardTile(currentBoard[7], 7, border: lrBorder),
                _drawBoardTile(currentBoard[8], 8),
              ],
            )
          ],
        );
      },
    );
  }

  _drawBoardTile(GamePiece gamepiece, position, {border}) {
    Color pieceColor = Colors.white;

    double calculatedBlocSize =  MediaQuery.of(context).size.width/3 - 20;
    double blockSize =  (calculatedBlocSize > 120) ? 120 : calculatedBlocSize;

    switch (gamepiece.pieceType) {
      case PieceType.win:
        pieceColor = Colors.yellow;
        break;
      case PieceType.normal:
      default:
        pieceColor = Colors.white;
        break;
    }
    return  GestureDetector(
        child: Container(
          decoration: BoxDecoration(border: border),
          height: blockSize,
          width: blockSize,
          child: Center(
              child: Text(
            gamepiece.piece,
            style: TextStyle(
              fontSize: 65.0,
              color: pieceColor,
              fontWeight: FontWeight.bold,
            ),
          )),
        ),
        onTap: () {
          _gameBloc.playPiece(position, false);
        },
      );
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
              child: Text(
                text,
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
            ),
            onPressed: onPressed),
      ),
    );
  }

  _scoreBox(String avatarUrl, String username, int score) {
    return FadeTransition(
          opacity:  _opacity,
          child: Column(
        children: <Widget>[
          CircleAvatar(
            child: Text(username.substring(0, 1)),
          ),
          Text(
            username,
            style: TextStyle(fontSize: 20.0),
          ),
          Text(
            score.toString(),
            style:
                TextStyle(color: Theme.of(context).accentColor, fontSize: 30.0),
          ),
        ],
      ),
    );
  }
}
