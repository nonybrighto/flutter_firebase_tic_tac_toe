import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';

class GameBoard extends StatefulWidget {
  GameBoard({Key key}) : super(key: key);

  @override
  _GameBoardState createState() => new _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  GameBloc _gameBloc;

  @override
  Widget build(BuildContext context) {
    _gameBloc = BlocProvider.of(context).gameBloc;
    return WillPopScope(
        onWillPop: _cancelGameDialog,
        child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 20.0),
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
            Expanded(
              child: Container(
                child: Center(child: _playBox()),
              ),
            ),
            StreamBuilder<bool>(
              initialData: false,
              stream: _gameBloc.allowReplay,
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

    );
  }

  Future<bool> _cancelGameDialog(){

    // return showDialog(
    //   context: context,
    //   builder: (context) => new AlertDialog(
    //     title: new Text('Are you sure?'),
    //     content: new Text('Do you want to exit an App'),
    //     actions: <Widget>[
    //       new FlatButton(
    //         onPressed: () => Navigator.of(context).pop(false),
    //         child: new Text('No'),
    //       ),
    //       new FlatButton(
    //         onPressed: () => Navigator.of(context).pop(true),
    //         child: new Text('Yes'),
    //       ),
    //     ],
    //   ),
    // ) ?? false;
    
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
                      Navigator.of(context).pop(true);
                     // Navigator.of(context).push(MaterialPageRoute(builder: (context) => MenuPage()));
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

    // return showDialog(
    //   context: context,
    //   child: new AlertDialog(
    //     title: new Text('Are you sure?'),
    //     content: new Text('Unsaved data will be lost.'),
    //     actions: <Widget>[
    //       new FlatButton(
    //         onPressed: () => Navigator.of(context).pop(false),
    //         child: new Text('No'),
    //       ),
    //       new FlatButton(
    //         onPressed: () => Navigator.of(context).pop(true),
    //         child: new Text('Yes'),
    //       ),
    //     ],
    //   ),
    // ) ?? false;
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _tt(currentBoard[0], 0),
                _tt(currentBoard[1], 1, border: lrBorder),
                _tt(currentBoard[2], 2),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _tt(currentBoard[3], 3, border: tbBorder),
                _tt(currentBoard[4], 4, border: centreBorder),
                _tt(currentBoard[5], 5, border: tbBorder),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _tt(currentBoard[6], 6),
                _tt(currentBoard[7], 7, border: lrBorder),
                _tt(currentBoard[8], 8),
              ],
            )
          ],
        );
      },
    );
  }

  _tt(GamePiece gamepiece, position, {border}) {
    Color pieceColor = Colors.white;

    switch (gamepiece.pieceType) {
      case PieceType.win:
        pieceColor = Colors.yellow;
        break;
      case PieceType.normal:
      default:
        pieceColor = Colors.white;
        break;
    }
    return Expanded(
      child: GestureDetector(
        child: Container(
          decoration: BoxDecoration(border: border),
          height: 120.0,
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
          _gameBloc.playPiece(position);
        },
      ),
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
    return Column(
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
    );
  }
}
