import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';
import 'package:flutter_firebase_tic_tac_toe/services/game_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_tic_tac_toe/services/user_service.dart';
import 'package:rxdart/rxdart.dart';

class GameBloc {
  final GameService gameService;
  final UserService userService;

  List<GamePiece> _currentBoardC = [];
  bool _gameOver = false;
  final _currentBoardSubject = BehaviorSubject<List<GamePiece>>(
      seedValue: List.generate(
          9, (index) => GamePiece(piece: '', pieceType: PieceType.normal)));

  final _currentPlayerSubject = BehaviorSubject<Player>(seedValue: Player());
  final _player1Subject = BehaviorSubject<Player>(seedValue: null);
  final _player2Subject = BehaviorSubject<Player>(seedValue: null);
  final _gameMessageSubject =
      BehaviorSubject<String>(seedValue: 'Tic - Tac - Toe');
  final _repeatCurrentGameSubject = BehaviorSubject<Null>(seedValue: null);
  final _handleChallengeSubject = BehaviorSubject<Map>();

  final _playPiece = BehaviorSubject<int>(seedValue: null);
  final _gameTypeSubject = BehaviorSubject<GameType>();
  final _multiNetworkMessage =
      BehaviorSubject<String>(seedValue: 'Tic Tac Toe ...');
  final _multiNetworkStarted = BehaviorSubject<bool>(seedValue: false);

  //sink
  Function(int) get playPiece => (position) => _playPiece.sink.add(position);
  Function() get repeatCurrentGame =>
      () => _repeatCurrentGameSubject.sink.add(null);
  Function(String, String, String, String, String, String, ChallengeHandleType)
      get handleChallenge => (senderId, senderName, senderFcmToken, receiverId,
              receiverName, receiverFcmToken, challengeHandleType) =>
          _handleChallengeSubject.sink.add({
            'senderId': senderId,
            'senderName': senderName,
            'senderFcmToken': senderFcmToken,
            'receiverId': receiverId,
            'receiverName': receiverName,
            'receiverFcmToken': receiverFcmToken,
            'challengeHandleType': challengeHandleType
          });

  Function(GameType) get gameType =>
      (gameType) => _gameTypeSubject.sink.add(gameType);

  //stream
  Stream<List<GamePiece>> get currentBoard => _currentBoardSubject.stream;
  Stream<Player> get player1 => _player1Subject.stream;
  Stream<Player> get player2 => _player2Subject.stream;
  Stream<Player> get currentPlayer => _currentPlayerSubject.stream;
  Stream<String> get gameMessage => _gameMessageSubject.stream;
  Stream<String> get multiNetworkMessage => _multiNetworkMessage.stream;
  Stream<bool> get multiNetworkStarted => _multiNetworkStarted.stream;

  GameBloc({this.gameService, this.userService}) {
    _handleChallengeSubject.stream.listen((challengeDetails) {
      String senderId = challengeDetails['senderId'];
      String senderName = challengeDetails['senderName'];
      String senderFcmToken = challengeDetails['senderFcmToken'];
      String receiverId = challengeDetails['receiverId'];
      String receiverName = challengeDetails['receiverName'];
      String receiverFcmToken = challengeDetails['receiverFcmToken'];
      ChallengeHandleType handleType = challengeDetails['challengeHandleType'];

      gameService.handleChallenge(senderId, senderName, senderFcmToken,
          receiverId, receiverName, receiverFcmToken, handleType);
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

    final playDetails = Observable.combineLatest4(
        _player1Subject,
        _player2Subject,
        _gameTypeSubject,
        _currentPlayerSubject, (player1, player2, gameType, currentPlayer) {
      return {
        'player1': player1,
        'player2': player2,
        'gameType': gameType,
        'currentPlayer': currentPlayer
      };
    });

    _playPiece.withLatestFrom(playDetails,
        (position, Map<String, dynamic> playDetails) {
      return {}..addAll(playDetails)..addAll({'position': position});
    }).listen((details) async{
      Player player1 = details['player1'];
      Player player2 = details['player2'];
      int position = details['position'];
      Player currentPlayer = details['currentPlayer'];
      GameType gameType = details['gameType'];
      User currentUser  = await userService.getCurrentUser();



      if (_currentBoardC[position].piece.isEmpty && !_gameOver) {
        if (gameType == GameType.multi_network) {

          if(currentPlayer.user.id == currentUser.id){

              //change turn 
             _changePlayerTurn(true);
             _currentBoardC[position] = currentPlayer.gamePiece.copyWith(pieceType: PieceType.temp);
             _currentBoardSubject.sink.add(_currentBoardC); // fill the space once user clicks before the network updates its own

              String networkGameId = player1.user.id+'_'+player2.user.id;
              
              gameService.playPiece(networkGameId, currentUser.id, position).catchError((err){
                  _changePlayerTurn(false);
                  _currentBoardC[position] = GamePiece(piece: '', pieceType: PieceType.normal);
                  _currentBoardSubject.sink.add(_currentBoardC);
              });

          }
          
        } else {
          _currentBoardC[position] = currentPlayer.gamePiece;
          final List<int> winLine = _getWinLine(_currentBoardC, currentPlayer);
          if (winLine.isNotEmpty) {
           
           _markWinLineOnBoard(winLine);

            _gameMessageSubject.sink.add(currentPlayer.user.name + ' wins!!!');

            if (currentPlayer.user.id == player1.user.id) {
              player1 = player1.copyWith(
                  score: player1.score + 1,
                  gamePiece:
                      player1.gamePiece.copyWith(pieceType: PieceType.normal));
              _player1Subject.sink.add(player1);
            } else {
              player2 = player2.copyWith(
                  score: player2.score + 1,
                  gamePiece:
                      player2.gamePiece.copyWith(pieceType: PieceType.normal));
              _player2Subject.sink.add(player2);
            }
            _gameOver = true;
          } else if (_isTie(_currentBoardC)) {
            _gameMessageSubject.sink.add("It's a tie !!!");
            _gameOver = true;
          } else {
            //change turn
            _changePlayerTurn(false);
          }
          _currentBoardSubject.sink.add(_currentBoardC);
        }
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

  _markWinLineOnBoard(List<int> winLine){
     _currentBoardC[winLine[0]] =
                _currentBoardC[winLine[0]].copyWith(pieceType: PieceType.win);
            _currentBoardC[winLine[1]] =
                _currentBoardC[winLine[1]].copyWith(pieceType: PieceType.win);
            _currentBoardC[winLine[2]] =
                _currentBoardC[winLine[2]].copyWith(pieceType: PieceType.win);
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

  _changePlayerTurn(bool temp, {idToUse}){

    Observable.combineLatest3(_currentPlayerSubject, _player1Subject, _player2Subject, (currentPlayer, player1, player2){

        return {'currentPlayer':currentPlayer, 'player1': player1, 'player2': player2};

    }).first.then((details){

      Player currentPlayer = details['currentPlayer'];
      Player player1 = details['player1'];
      Player player2 = details['player2'];

      String tempString = temp ? '...' : '';

        Player currentSetPlayer;
        if(idToUse != null){
            Player playerWithId = [player1, player2].firstWhere((player) => player.user.id == idToUse);
            currentSetPlayer = playerWithId;
        }else{
          //  if (currentPlayer.user.id == player1.user.id) {
          //         _currentPlayerSubject.sink.add(player2);
          //       _gameMessageSubject.sink.add(player2.user.name + "'s turn"+tempString);  
          //     } else {
          //       _currentPlayerSubject.sink.add(player1);
          //       _gameMessageSubject.sink.add(player1.user.name + "'s turn"+tempString);
          //   }
            Player swappedCurrentPlayer = [player1, player2].firstWhere((player) => player.user.id != currentPlayer.user.id);
            currentSetPlayer = swappedCurrentPlayer;
            
        }
         _currentPlayerSubject.sink.add(currentSetPlayer);
         _gameMessageSubject.sink.add(currentSetPlayer.user.name + "'s turn"+tempString);



    });
  }

  startServerGame(String player1Id, player2Id) {
    String gameId = player1Id + '_' + player2Id;

    Firestore.instance
        .collection('games')
        .document(gameId)
        .snapshots()
        .listen((snapshot) async{
            print(snapshot);
            print('snapshot');

            Map<String, dynamic> gameData = snapshot.data;

            _drawNetworkPlayer(gameData['player1'], _player1Subject);
            _drawNetworkPlayer(gameData['player2'], _player2Subject);
            _drawNetworkBoard(gameData['pieces']);
           
           if(gameData['winner'].isNotEmpty && gameData['winner'] != 'tie'){
            
              Player gameWinner = await _getPlayerFromId(gameData['winner']);
              _gameMessageSubject.sink.add(gameWinner.user.name + ' wins!!!');
              List<int> winLine = _getWinLine(_currentBoardC, gameWinner);
              _markWinLineOnBoard(winLine);
              _currentBoardSubject.sink.add(_currentBoardC);
              _gameOver = true;

           }else if(gameData['winner'] == 'tie'){
                  print('its a tie');
                  //TODO: handle tie option including making it the time play again button shows up
                  _gameMessageSubject.sink.add("It's a tie !!!");
                  _gameOver = true;
           }else{
            _changePlayerTurn(false, idToUse: gameData['currentPlayer']);
           }
    }).onError((error){
        print(error);
    });

    //get the game from the server and listen for it here
    _gameTypeSubject.sink.add(GameType.multi_network);

    _multiNetworkMessage.sink
        .add('Game has been Started! Click button to play');
    _multiNetworkStarted.sink.add(true);
  }

  _drawNetworkPlayer(Map player, playerSubject) {
    Player gottenPlayer = Player(
        gamePiece:
            GamePiece(piece: player['gamePiece'], pieceType: PieceType.normal),
        score: player['score'],
        user: User(id: player['user']['id'], name: player['user']['name']));

    playerSubject.sink.add(gottenPlayer);
  }

  Future<Player> _getPlayerFromId(String playerId) async{

    List<Player> players = await Observable.combineLatest2(_player1Subject, _player2Subject, (Player p1, Player p2){

      return<Player>[p1, p2];
    }).first;

    return players.firstWhere((player) => player.user.id == playerId);
  }

  _drawNetworkBoard(Map networkPieces) {
    List<GamePiece> pieces = networkPieces.values
        .toList()
        .map((piece) => GamePiece(piece: piece, pieceType: PieceType.normal))
        .toList();
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
    _gameTypeSubject.close();
    _multiNetworkMessage.close();
    _multiNetworkStarted.close();
  }
}
