import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';
import 'package:flutter_firebase_tic_tac_toe/services/game_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

class GameBloc {

  GameService gameService;

  List<GamePiece> _currentBoardC = [];
  bool _gameOver = false;
  final _currentBoardSubject = BehaviorSubject<List<GamePiece>>(
      seedValue: List.generate(9, (index) => GamePiece(piece:'', pieceType:PieceType.normal)));

  final _currentPlayerSubject = BehaviorSubject<Player>(seedValue: null);
  final _player1Subject = BehaviorSubject<Player>(seedValue: null);
  final _player2Subject = BehaviorSubject<Player>(seedValue: null);
  final _gameMessageSubject =
      BehaviorSubject<String>(seedValue: 'Tic - Tac - Toe');
  final _repeatCurrentGameSubject = BehaviorSubject<Null>(seedValue: null);
  final _handleChallengeSubject = BehaviorSubject<Map>();

  final _playPiece = BehaviorSubject<int>(seedValue: null);
  final _gameType = BehaviorSubject<GameType>();
  final _multiNetworkMessage = BehaviorSubject<String>(seedValue: 'Tic Tac Toe ...');
  final _multiNetworkStarted = BehaviorSubject<bool>(seedValue: false);

  //sink
  Function(int) get playPiece => (position) => _playPiece.sink.add(position);
  Function() get repeatCurrentGame =>
      () => _repeatCurrentGameSubject.sink.add(null);
  Function(String, String, String, String, String, String, ChallengeHandleType) get handleChallenge => (senderId, senderName, senderFcmToken,  receiverId, receiverName, receiverFcmToken, challengeHandleType) => _handleChallengeSubject.sink.add({'senderId': senderId, 'senderName': senderName, 'senderFcmToken': senderFcmToken, 'receiverId':receiverId,  'receiverName':receiverName, 'receiverFcmToken': receiverFcmToken, 'challengeHandleType': challengeHandleType});

  Function(GameType) get gameType => (gameType) => _gameType.sink.add(gameType);

  //stream
  Stream<List<GamePiece>> get currentBoard => _currentBoardSubject.stream;
  Stream<Player> get player1 => _player1Subject.stream;
  Stream<Player> get player2 => _player2Subject.stream;
  Stream<Player> get currentPlayer => _currentPlayerSubject.stream;
  Stream<String> get gameMessage => _gameMessageSubject.stream;
  Stream<String> get multiNetworkMessage => _multiNetworkMessage.stream;
  Stream<bool> get multiNetworkStarted => _multiNetworkStarted.stream;

  GameBloc({this.gameService}) {

    _handleChallengeSubject.stream.listen((challengeDetails){

        String senderId = challengeDetails['senderId'];
        String senderName = challengeDetails['senderName'];
        String senderFcmToken = challengeDetails['senderFcmToken'];
         String receiverId = challengeDetails['receiverId'];
        String receiverName = challengeDetails['receiverName'];
        String receiverFcmToken = challengeDetails['receiverFcmToken'];
        ChallengeHandleType handleType = challengeDetails['challengeHandleType'];


        gameService.handleChallenge(senderId, senderName, senderFcmToken, receiverId, receiverName, receiverFcmToken, handleType);

    });

    _currentBoardC = List.generate(
        9, (index) => GamePiece(piece: '', pieceType: PieceType.normal));

    //TODO: remove
    _player1Subject.sink.add(Player(
        user: User(id: 'Peter', name: 'peter', avatarUrl: 'peter'),
        gamePiece: GamePiece(piece: 'X', pieceType: PieceType.normal),
        score: 0));
    _player2Subject.sink.add(Player(
        user: User(id: 'Ada', name: 'Ada', avatarUrl: 'peter'),
        gamePiece: GamePiece(piece: 'O', pieceType: PieceType.normal),
        score: 0));
    _currentPlayerSubject.sink.add(Player(
        user: User(id: 'Peter', name: 'peter', avatarUrl: 'peter'),
        gamePiece: GamePiece(piece: 'X', pieceType: PieceType.normal),
        score: 0));

    final players =
        Observable.combineLatest2(_player1Subject, _player2Subject, (player1, player2) {
      return {'player1': player1, 'player2': player2};
    });

    _playPiece.withLatestFrom(_currentPlayerSubject,
        (position, Player currentPlayer) {
      return {'position': position, 'currentPlayer': currentPlayer};
    }).withLatestFrom(players, (currentPlay, players) {
      return {}..addAll(currentPlay)..addAll(players);
    }).listen((details) {
      Player player1 = details['player1'];
      Player player2 = details['player2'];
      int position = details['position'];
      Player currentPlayer = details['currentPlayer'];

      if (_currentBoardC[position].piece.isEmpty && !_gameOver) {
        _currentBoardC[position] = currentPlayer.gamePiece;
        final List<int> winLine = _getWinLine(_currentBoardC, currentPlayer);
        if (winLine.isNotEmpty) {

         _currentBoardC[winLine[0]] = _currentBoardC[winLine[0]].copyWith(pieceType: PieceType.win);
        _currentBoardC[winLine[1]] = _currentBoardC[winLine[1]].copyWith(pieceType: PieceType.win);
         _currentBoardC[winLine[2]] =  _currentBoardC[winLine[2]].copyWith(pieceType: PieceType.win);

          _gameMessageSubject.sink.add(currentPlayer.user.name + ' wins!!!');

          if (currentPlayer.user.id == player1.user.id) {
            player1 = player1.copyWith(score: player1.score + 1, gamePiece: player1.gamePiece.copyWith(pieceType: PieceType.normal));
            _player1Subject.sink.add(player1);
          } else {
             player2 = player2.copyWith(score: player2.score + 1, gamePiece: player2.gamePiece.copyWith(pieceType: PieceType.normal));
            _player2Subject.sink.add(player2);
          }
          _gameOver = true;
        } else if (_isTie(_currentBoardC)) {
          _gameMessageSubject.sink.add("It's a tie !!!");
          _gameOver = true;
        } else {
          //change turn
          if (currentPlayer.user.id == player1.user.id) {
            _currentPlayerSubject.sink.add(player2);
            _gameMessageSubject.sink.add(player2.user.name + "'s turn");
          } else {
            _currentPlayerSubject.sink.add(player1);
            _gameMessageSubject.sink.add(player1.user.name + "'s turn");
          }
        }
        _currentBoardSubject.sink.add(_currentBoardC);
      }
    });

    _repeatCurrentGameSubject.withLatestFrom(_currentPlayerSubject,
        (_, currentPlayer) {
      return currentPlayer;
    }).listen((currentPlayer) {
      _currentBoardC = List.generate(
          9, (index) => GamePiece(piece: '', pieceType: PieceType.normal));
      _currentBoardSubject.sink.add(_currentBoardC);

      _gameMessageSubject.sink.add(currentPlayer.user.name + "'s turn");
      _gameOver = false;
    });
  }

  bool _isTie(List<GamePiece> gameBoard) {
    int emptyIndex = gameBoard.indexWhere((gamePiece) => gamePiece.piece == '');
    return emptyIndex == -1;
  }

  List<int> _getWinLine(List<GamePiece> gameBoard, Player player) {
    List<List<int>> possibleWins = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6]
    ];
    for (int i = 0; i < possibleWins.length; i++) {
      List<int> currentPossibleWin = possibleWins[i];
      String playerPiece = player.gamePiece.piece;
      if (gameBoard[currentPossibleWin[0]].piece == playerPiece &&
          gameBoard[currentPossibleWin[1]].piece == playerPiece &&
          gameBoard[currentPossibleWin[2]].piece == playerPiece) {
        return currentPossibleWin;
      }
    }
    return [];
  }


  startServerGame(String player1Id, player2Id){


              String gameId = player1Id+'_'+player2Id;

              Firestore.instance.collection('games').document(gameId).snapshots().listen((snapshot){

                      print(snapshot);
                       print('snapshot');

                      Map<String, dynamic> gameData = snapshot.data;

                      _drawNetworkPlayer(gameData['player1'], _player1Subject);
                      _drawNetworkPlayer(gameData['player2'], _player2Subject);
                      _drawNetworkBoard(gameData['pieces']);
                      _drawCurrentPlayer(gameData['currentPlayer']);


              });

            //get the game from the server and listen for it here
            _gameType.sink.add(GameType.multi_network);

            _multiNetworkMessage.sink.add('Game has been Started! Click button to play');
            _multiNetworkStarted.sink.add(true);

  }

  _drawNetworkPlayer(Map player, playerSubject){

    Player gottenPlayer = Player(gamePiece: GamePiece(piece: player['gamePiece'], pieceType: PieceType.normal), score: player['score'], user: User(id: player['user']['id'], name: player['user']['name']));

    playerSubject.sink.add(gottenPlayer);
  }

  _drawCurrentPlayer(String playerId){

        Observable.combineLatest2(_player1Subject, _player2Subject, (Player player1,  Player player2){

            return [player1, player2];
        }).listen((List<Player> players){

             Player playerWithId = players.firstWhere((player) => player.user.id == playerId);
             _currentPlayerSubject.sink.add(playerWithId);
        });

  }

  _drawNetworkBoard(Map networkPieces){

       List<GamePiece>  pieces =  networkPieces.values.toList().map((piece) => GamePiece(piece:  piece, pieceType: PieceType.normal)).toList();
       _currentBoardC = pieces;
       _currentBoardSubject.sink.add(_currentBoardC);
  
  }

  close() {
    _gameMessageSubject.close();
    _currentBoardSubject.close();
    _currentPlayerSubject.close();
    _player1Subject.close();
    _player2Subject.close();
    _repeatCurrentGameSubject.close();
    _handleChallengeSubject.close();
    _gameType.close();
    _multiNetworkMessage.close();
    _multiNetworkStarted.close();
  }
}
