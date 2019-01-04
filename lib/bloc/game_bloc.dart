import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';
import 'package:rxdart/rxdart.dart';

class GameBloc{


  List<GamePiece> _currentBoardC = [];
  bool _gameOver = false;
  final _currentBoardSubject = BehaviorSubject<List<GamePiece>>(seedValue:List.generate(9, (index) => GamePiece('', PieceType.normal)));

  final _currentPlayerSubject = BehaviorSubject<Player>(seedValue: null);
  final _player1Subject = BehaviorSubject<Player>(seedValue: null);
  final _player2Subject = BehaviorSubject<Player>(seedValue: null);
  final _gameMessageSubject = BehaviorSubject<String>(seedValue: 'Tic - Tac - Toe');
  final _repeatCurrentGameSubject = BehaviorSubject<Null>(seedValue: null);

  final _playPiece = BehaviorSubject<int>(seedValue: null);

  //sink
  Function(int) get playPiece => (position) => _playPiece.sink.add(position);
  Function() get repeatCurrentGame => () => _repeatCurrentGameSubject.sink.add(null);
  //stream
  Stream<List<GamePiece>>   get currentBoard => _currentBoardSubject.stream;
  Stream<Player> get player1 => _player1Subject.stream;
  Stream<Player> get player2 => _player2Subject.stream;
  Stream<Player> get currentPlayer => _currentPlayerSubject.stream;
  Stream<String> get gameMessage => _gameMessageSubject.stream;


  GameBloc(){
    _currentBoardC = List.generate(9, (index) => GamePiece('', PieceType.normal));

    //TODO: remove
    _player1Subject.sink.add(Player(User(id: 'Peter', name: 'peter', avatarUrl: 'peter'), GamePiece('X', PieceType.normal), 0));
    _player2Subject.sink.add(Player(User(id: 'Ada', name: 'Ada', avatarUrl: 'peter'),  GamePiece('O', PieceType.normal), 0));
    _currentPlayerSubject.sink.add(Player(User(id: 'Peter', name: 'peter', avatarUrl: 'peter'), GamePiece('X', PieceType.normal), 0));


    final players = Observable.combineLatest2(_player1Subject, player2, (player1, player2){

          return {'player1': player1, 'player2': player2};
    });


    _playPiece.withLatestFrom(_currentPlayerSubject, (position , Player currentPlayer){
          return {'position': position, 'currentPlayer': currentPlayer};

     }).withLatestFrom(players, (currentPlay, players){
          return {}..addAll(currentPlay)..addAll(players);
     }).listen((details){
       Player player1 = details['player1'];
       Player player2 = details['player2'];
       int position = details['position'];
       Player currentPlayer = details['currentPlayer'];

         if(_currentBoardC[position].piece.isEmpty && !_gameOver){
          
          _currentBoardC[position] = currentPlayer.gamePiece;
          final List<int> winLine = _getWinLine(_currentBoardC, currentPlayer);
          if(winLine.isNotEmpty){

              // _currentBoardC[0].pieceType = PieceType.win;
              // _currentBoardC[1].pieceType = PieceType.win;
              // _currentBoardC[2].pieceType = PieceType.win;
              _currentBoardC[winLine[0]].pieceType = PieceType.win;
              _currentBoardC[winLine[1]].pieceType = PieceType.win;
              _currentBoardC[winLine[2]].pieceType = PieceType.win;

              

              _gameMessageSubject.sink.add(currentPlayer.user.name + ' wins!!!');

              if(currentPlayer.user.id == player1.user.id){
                player1.score = player1.score + 1;
                player1.gamePiece.pieceType = PieceType.normal;
                _player1Subject.sink.add(player1);
              }else{
                player2.score = player2.score + 1;
                player2.gamePiece.pieceType = PieceType.normal;
                _player2Subject.sink.add(player2);
              }
              _gameOver = true;

          }else if(_isTie(_currentBoardC)){
              _gameMessageSubject.sink.add("It's a tie !!!");
              _gameOver = true;
          }else{
             //change turn
            if(currentPlayer.user.id == player1.user.id){
              _currentPlayerSubject.sink.add(player2);
              _gameMessageSubject.sink.add(player2.user.name+"'s turn");
            }else{
              _currentPlayerSubject.sink.add(player1);
              _gameMessageSubject.sink.add(player1.user.name+"'s turn");
            }
          }
           _currentBoardSubject.sink.add(_currentBoardC);
         }
    });

   _repeatCurrentGameSubject.withLatestFrom(_currentPlayerSubject, (_, currentPlayer){
        return currentPlayer;
   }).listen((currentPlayer){

        _currentBoardC = List.generate(9, (index) => GamePiece('', PieceType.normal));
        _currentBoardSubject.sink.add(_currentBoardC);

        _gameMessageSubject.sink.add(currentPlayer.user.name+"'s turn");
        _gameOver = false;

   });

    
  }

  bool _isTie(List<GamePiece> gameBoard){

        int emptyIndex = gameBoard.indexWhere((gamePiece) => gamePiece.piece == '');
        return emptyIndex == -1;
  }

  List<int> _getWinLine(List<GamePiece> gameBoard, Player player){
          List<List<int>> possibleWins = [
              [0,1,2],
              [3,4,5],
              [6,7,8],
              [0,3,6],
              [1,4,7],
              [2,5,8],
              [0,4,8],
              [2,4,6]
          ];
       for(int i = 0; i < possibleWins.length; i++){
           List<int> currentPossibleWin = possibleWins[i];
           String playerPiece = player.gamePiece.piece;
           if(gameBoard[currentPossibleWin[0]].piece == playerPiece &&
              gameBoard[currentPossibleWin[1]].piece == playerPiece &&
              gameBoard[currentPossibleWin[2]].piece == playerPiece){

                    return currentPossibleWin;
           }
       }
       return [];
  }


  close(){
    _gameMessageSubject.close();
    _currentBoardSubject.close();
    _currentPlayerSubject.close();
    _player1Subject.close();
    _player2Subject.close();
    _repeatCurrentGameSubject.close();
  }
}