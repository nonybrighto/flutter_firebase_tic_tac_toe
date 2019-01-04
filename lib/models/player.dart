import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game_piece.dart';

class Player{

  User user;
  GamePiece gamePiece;
  int score;

  Player(this.user, this.gamePiece, this.score);
}