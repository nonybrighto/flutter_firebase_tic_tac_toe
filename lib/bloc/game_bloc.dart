import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';
import 'package:flutter_firebase_tic_tac_toe/models/player.dart';
import 'package:flutter_firebase_tic_tac_toe/services/game_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_tic_tac_toe/services/user_service.dart';
import 'package:rxdart/rxdart.dart';

class GameBloc extends BlocBase {
  final GameService gameService;
  final UserService userService;
  StreamSubscription<DocumentSnapshot> _serverGameSub;

  List<GamePiece> _currentBoardC = [];
  bool _gameOver = false;
  GameType _gameType = GameType.computer;

  final _currentBoardSubject = BehaviorSubject<List<GamePiece>>();

  final _currentPlayerSubject = BehaviorSubject<Player>(seedValue: Player());
  final _player1Subject = BehaviorSubject<Player>();
  final _player2Subject = BehaviorSubject<Player>();
  final _gameMessageSubject = BehaviorSubject<String>(seedValue: '');
  final _replayCurrentGameSubject = BehaviorSubject<Null>();
  final _handleChallengeSubject = BehaviorSubject<Map>();
  final _gameOverSubject = BehaviorSubject<bool>();
  final _playPiece = BehaviorSubject<Map<String, dynamic>>();
  final _multiNetworkMessage =
      BehaviorSubject<String>(seedValue: 'Tic Tac Toe ...');
  final _multiNetworkStarted = BehaviorSubject<bool>();
  final _cancelGameSubject = BehaviorSubject<Null>();
  final _startSingleDeviceGame = BehaviorSubject<GameType>();

  final _clearProcessDetails = BehaviorSubject<Null>();
  final _startServerGame = BehaviorSubject<Map<String, String>>();

  //sink
  Function(int, bool) get playPiece => (position, isAuto) => _playPiece.sink.add({'position':position, 'isAuto': isAuto});
  Function() get cancelGame => () => _cancelGameSubject.sink.add(null);
  Function() get replayCurrentGame =>
      () => _replayCurrentGameSubject.sink.add(null);
  Function(User, ChallengeHandleType) get handleChallenge =>
      (receiver, challengeHandleType) => _handleChallengeSubject.sink.add(
          {'receiver': receiver, 'challengeHandleType': challengeHandleType});

  Function(GameType) get startSingleDeviceGame =>
      (gameType) => _startSingleDeviceGame.sink.add(gameType);
  Function() get clearProcessDetails =>
      () => _clearProcessDetails.sink.add(null);
  Function(String, String) get startServerGame =>
      (player1Id, player2Id) => _startServerGame.sink
          .add({'player1Id': player1Id, 'player2Id': player2Id});
  Function(bool) get changeGameOver =>
      (allowReplay) => _gameOverSubject.sink.add(allowReplay);

  //stream
  Stream<List<GamePiece>> get currentBoard => _currentBoardSubject.stream;
  Stream<Player> get player1 => _player1Subject.stream;
  Stream<Player> get player2 => _player2Subject.stream;
  Stream<Player> get currentPlayer => _currentPlayerSubject.stream;
  Stream<String> get gameMessage => _gameMessageSubject.stream;
  Stream<String> get multiNetworkMessage => _multiNetworkMessage.stream;
  Stream<bool> get multiNetworkStarted => _multiNetworkStarted.stream;
  Stream<bool> get gameOver => _gameOverSubject.stream;

  GameBloc({this.gameService, this.userService}) {
    _emptyGameBoard();

    _handleChallengeSubject.stream.listen(_handleChallenge);

    _gameOverSubject.stream.listen((gameOver) {
      _gameOver = gameOver;
    });

    _startSingleDeviceGame.stream.listen(_handleStartSingleDeviceGame);

    _playPiece.withLatestFrom(_currentPlayerSubject,
        (Map<String, dynamic> playDetails, Player currentPlayer) {
     // return {'position': position, 'currentPlayer':currentPlayer};
      return {}..addAll(playDetails)..addAll({'currentPlayer':currentPlayer});
    }).listen(_handlePlayPiece);

    _cancelGameSubject.listen(_handleCancelGame);

    _replayCurrentGameSubject.withLatestFrom(_currentPlayerSubject,
        (_, Player currentPlayer) {
      return currentPlayer;
    }).listen(_handleReplayCurrentGame);

    _startServerGame.stream.listen(_handleStartServerGame);

    _clearProcessDetails.stream.listen(_handleClearProcessDetails);
  }

  _handleChallenge(challengeDetails) async {
    User sender = await userService.getCurrentUser();
    User receiver = challengeDetails['receiver'];
    ChallengeHandleType handleType = challengeDetails['challengeHandleType'];

    gameService.handleChallenge(sender, receiver, handleType);
  }

  _handleStartSingleDeviceGame(gameType) async {
    _gameType = gameType;

    if (gameType == GameType.multi_device) {
      _player1Subject.sink.add(Player(
          user: User(id: 'Player1', name: 'Player1', avatarUrl: 'peter'),
          gamePiece: GamePiece(piece: 'X', pieceType: PieceType.normal),
          score: 0));
      _player2Subject.sink.add(Player(
          user: User(id: 'Player2', name: 'Player2', avatarUrl: 'peter'),
          gamePiece: GamePiece(piece: 'O', pieceType: PieceType.normal),
          score: 0));

      Player currentPlayer = await _player1Subject.first;
      _currentPlayerSubject.sink.add(currentPlayer);
      _gameMessageSubject.sink.add(currentPlayer.user.name + "'s turn");
    } else if (gameType == GameType.computer) {
      _player1Subject.sink.add(Player(
          user: User(id: 'User', name: 'User', avatarUrl: 'user'),
          gamePiece: GamePiece(piece: 'X', pieceType: PieceType.normal),
          score: 0));
      _player2Subject.sink.add(Player(
          user: User(id: 'Computer', name: 'Computer', avatarUrl: 'computer'),
          gamePiece: GamePiece(piece: 'O', pieceType: PieceType.normal),
          score: 0));

      Player currentPlayer = await _player1Subject.first;
      _currentPlayerSubject.sink.add(currentPlayer);
      _gameMessageSubject.sink.add(currentPlayer.user.name + "'s turn");
    }

    _gameOverSubject.sink.add(false);
    _emptyGameBoard();
  }

  _handlePlayPiece(details) async {

    List<Player> players = await _getPlayers();
    Player player1 = players[0];
    Player player2 = players[1];
    int position = details['position'];
    Player currentPlayer = details['currentPlayer'];
    bool isAuto = details['isAuto'];

    User currentUser = await userService.getCurrentUser();

    if (_currentBoardC[position].piece.isEmpty && !_gameOver) {
      if (_gameType == GameType.multi_network) {
        if (currentPlayer.user.id == currentUser.id) {
          //change turn
          _changePlayerTurn(true);
          _currentBoardC[position] =
              currentPlayer.gamePiece.copyWith(pieceType: PieceType.temp);
          _currentBoardSubject.sink.add(
              _currentBoardC); // fill the space once user clicks before the network updates its own

          String networkGameId = player1.user.id + '_' + player2.user.id;

          gameService
              .playPiece(networkGameId, currentUser.id, position)
              .catchError((err) {
            _changePlayerTurn(false);
            _currentBoardC[position] =
                GamePiece(piece: '', pieceType: PieceType.normal);
            _currentBoardSubject.sink.add(_currentBoardC);
          });
        }
      } else {
        if(_gameType == GameType.multi_device || isAuto || (currentPlayer.user.id == 'User')){
        _currentBoardC[position] = currentPlayer.gamePiece;
        final List<int> winLine =
            _getWinLine(_currentBoardC, currentPlayer.gamePiece.piece);
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
          _gameOverSubject.sink.add(true);
        } else if (_isTie(_currentBoardC)) {
          _gameMessageSubject.sink.add("It's a tie !!!");
          _gameOverSubject.sink.add(true);
        } else {
          //change turn
          _changePlayerTurn(false);
          //if the last player is a user, then computer can play own piece
          if (_gameType == GameType.computer &&
              currentPlayer.user.name == 'User') {
            _playComputerPiece();
          }
        }
        _currentBoardSubject.sink.add(_currentBoardC);
      }
      }
    }
  }

  _handleCancelGame(_) async {
    if (_gameType == GameType.multi_network) {
      List<Player> players = await _getPlayers();

      String gameId = players[0].user.id + '_' + players[1].user.id;
      User currentUser = await userService.getCurrentUser();
      try {
        gameService.cancelGame(gameId, currentUser.id);
        _serverGameSub.cancel();
      } catch (err) {
        print(err);
      }
    }
  }

  _handleReplayCurrentGame(currentPlayer) async {
    if (_gameType == GameType.multi_network) {
      //get players
      List<Player> players = await _getPlayers();

      String gameId = players[0].user.id + '_' + players[1].user.id;
      User currentUser = await userService.getCurrentUser();

      try {
        await gameService.replayGame(gameId, currentUser.id);
      } catch (err) {
        print(err);
      }
    } else {
      _emptyGameBoard();
      _gameOverSubject.sink.add(false);
      if (_gameType == GameType.computer &&
          currentPlayer.user.name == 'Computer') {
        _playComputerPiece();
      }
      _gameMessageSubject.sink.add(currentPlayer.user.name + "'s turn");
    }
  }

  _handleStartServerGame(playersId) {
    _gameOverSubject.sink.add(false);
    _gameType = GameType.multi_network;

    String player1Id = playersId['player1Id'];
    String player2Id = playersId['player2Id'];

    String gameId = player1Id + '_' + player2Id;

    _serverGameSub = Firestore.instance
        .collection('games')
        .document(gameId)
        .snapshots()
        .listen((snapshot) async {
      Map<String, dynamic> gameData = snapshot.data;

      _setNetworkPlayer(gameData['player1'], _player1Subject);
      _setNetworkPlayer(gameData['player2'], _player2Subject);
      _setNetworkBoard(gameData['pieces']);

      if (gameData['winner'].isNotEmpty && gameData['winner'] != 'tie') {
        Player gameWinner = await _getPlayerFromId(gameData['winner']);
        List<int> winLine =
            _getWinLine(_currentBoardC, gameWinner.gamePiece.piece);
        _markWinLineOnBoard(winLine);
        _currentBoardSubject.sink.add(_currentBoardC);
        _gameMessageSubject.sink.add(gameWinner.user.name + ' wins!!!');
        _gameOverSubject.sink.add(true);
      } else if (gameData['winner'] == 'tie') {
        print('its a tie');
        _gameMessageSubject.sink.add("It's a tie !!!");
        _gameOverSubject.sink.add(true);
      } else {
        _changePlayerTurn(false, idToUse: gameData['currentPlayer']);
      }
    })
          ..onError((error) {
            print(error);
          });

    _multiNetworkMessage.sink
        .add('Game has been Started! Click button to play');
    _multiNetworkStarted.sink.add(true);
  }

  _handleClearProcessDetails(_) {
    _multiNetworkMessage.sink.add('Tic Tac Toe');
    _multiNetworkStarted.sink.add(false);
  }

  _playComputerPiece() {
    Future.delayed(Duration(seconds: 1), () async {
      int bestPostion = await _getComputerPlayPosition();
      playPiece(bestPostion, true);
     // _playPiece.sink.add({'position': bestPostion , 'isAuto': true});
      
    });
  }

  _emptyGameBoard() {
    _currentBoardC = List.generate(
        9, (index) => GamePiece(piece: '', pieceType: PieceType.normal));
    _currentBoardSubject.sink.add(_currentBoardC);
  }

  _markWinLineOnBoard(List<int> winLine) {
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

  Future<int> _getComputerPlayPosition() async {
    Player currentPlayer = await _currentPlayerSubject.first;
    return _getBestMove(currentPlayer);
  }

  List<int> _getWinLine(List<GamePiece> gameBoard, String playerPiece) {
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
      if (gameBoard[currentPossibleWin[0]].piece == playerPiece &&
          gameBoard[currentPossibleWin[1]].piece == playerPiece &&
          gameBoard[currentPossibleWin[2]].piece == playerPiece) {
        return currentPossibleWin;
      }
    }
    return [];
  }

  _changePlayerTurn(bool temp, {idToUse}) {
    Observable.combineLatest3(
        _currentPlayerSubject, _player1Subject, _player2Subject,
        (currentPlayer, player1, player2) {
      return {
        'currentPlayer': currentPlayer,
        'player1': player1,
        'player2': player2
      };
    }).first.then((details) {
      Player currentPlayer = details['currentPlayer'];
      Player player1 = details['player1'];
      Player player2 = details['player2'];

      String tempString = temp ? '...' : '';

      Player currentSetPlayer;
      if (idToUse != null) {
        Player playerWithId = [player1, player2]
            .firstWhere((player) => player.user.id == idToUse);
        currentSetPlayer = playerWithId;
      } else {
        Player swappedCurrentPlayer = [player1, player2]
            .firstWhere((player) => player.user.id != currentPlayer.user.id);
        currentSetPlayer = swappedCurrentPlayer;
      }
      _currentPlayerSubject.sink.add(currentSetPlayer);
      _gameMessageSubject.sink
          .add(currentSetPlayer.user.name + "'s turn" + tempString);
    });
  }

  _setNetworkPlayer(Map player, playerSubject) {
    Player gottenPlayer = Player(
        gamePiece:
            GamePiece(piece: player['gamePiece'], pieceType: PieceType.normal),
        score: player['score'],
        user: User(
            id: player['user']['id'],
            name: player['user']['name'],
            fcmToken: player['user']['fcmToken']));

    playerSubject.sink.add(gottenPlayer);
  }

  Future<Player> _getPlayerFromId(String playerId) async {
    List<Player> players = await _getPlayers();
    return players.firstWhere((player) => player.user.id == playerId);
  }

  Future<List<Player>> _getPlayers() async {
    return await Observable.combineLatest2(_player1Subject, _player2Subject,
        (Player player1, Player player2) {
      return <Player>[player1, player2];
    }).first;
  }

  _setNetworkBoard(Map networkPieces) {
    //Added this bcus the map gotten from firebase is not in a specific order.
    final sortedMap = SplayTreeMap<dynamic, dynamic>();
    sortedMap.addAll(networkPieces);

    List<GamePiece> pieces = sortedMap.values
        .toList()
        .map((piece) => GamePiece(piece: piece, pieceType: PieceType.normal))
        .toList();
    _currentBoardC = pieces;
    _currentBoardSubject.sink.add(_currentBoardC);
  }

  int _getBestMove(Player player) {
    String playerPiece = player.gamePiece.piece;
    String opponentPiece = (playerPiece == 'X') ? 'O' : 'X';

    int winningPosition = _checkWinMove(playerPiece);
    int defencePosition = _checkWinMove(opponentPiece);
    if (winningPosition != null) {
      return winningPosition;
    } else if (defencePosition != null) {
      return defencePosition;
    } else {
      //play on any random empty position
      List<int> emptyPos = _emptyBoardPositions();
      int randPos = Random().nextInt(emptyPos.length);
      return emptyPos[randPos];
    }
  }

  _emptyBoardPositions() {
    List<int> emptyPos = [];
    for (int i = 0; i < _currentBoardC.length; i++) {
      if (_currentBoardC[i].piece == '') {
        emptyPos.add(i);
      }
    }
    return emptyPos;
  }

  int _checkWinMove(piece) {
    List<int> emptyPos = _emptyBoardPositions();

    List<GamePiece> testBoard = []..addAll(_currentBoardC);
    for (int i = 0; i < emptyPos.length; i++) {
      testBoard[emptyPos[i]] =
          GamePiece(piece: piece, pieceType: PieceType.normal);
      if (_getWinLine(testBoard, piece).isNotEmpty) {
        return emptyPos[i];
      } else {
        testBoard[emptyPos[i]] =
            GamePiece(piece: '', pieceType: PieceType.normal);
      }
    }
    return null;
  }

  @override
  void dispose() {
    _gameMessageSubject.close();
    _currentBoardSubject.close();
    _currentPlayerSubject.close();
    _player1Subject.close();
    _player2Subject.close();
    _replayCurrentGameSubject.close();
    _handleChallengeSubject.close();
    _multiNetworkMessage.close();
    _multiNetworkStarted.close();
    _gameOverSubject.close();
    _startSingleDeviceGame.close();
    _clearProcessDetails.close();
    _startServerGame.close();
  }
}
