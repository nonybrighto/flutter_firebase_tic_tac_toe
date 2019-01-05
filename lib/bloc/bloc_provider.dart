
import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';

class BlocProvider extends InheritedWidget { 

  final GameBloc gameBloc;
  final UserBloc userBloc;
  BlocProvider({Key key, this.gameBloc, this.userBloc, Widget child}) : super(key: key, child: child);

  bool updateShouldNotify(_) => true;

  static BlocProvider of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(BlocProvider) as BlocProvider);
  }
}