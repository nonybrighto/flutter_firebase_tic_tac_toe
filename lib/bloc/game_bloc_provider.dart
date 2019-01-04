
import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';

class GameBlocProvider extends InheritedWidget {

  final GameBloc gameBloc;
  GameBlocProvider({Key key, this.gameBloc, Widget child}) : super(key: key, child: child);

  bool updateShouldNotify(_) => true;

  static GameBlocProvider of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(GameBlocProvider) as GameBlocProvider);
  }
}