import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/game_board.dart';

class GameProcessPage extends StatefulWidget {
  GameProcessPage({Key key}) : super(key: key);

  @override
  _GameProcessPageState createState() => new _GameProcessPageState();
}

class _GameProcessPageState extends State<GameProcessPage> {

  GameBloc _gameBloc;

  @override
  Widget build(BuildContext context) {
    _gameBloc = BlocProvider.of(context).gameBloc;
    return Scaffold(

      body:Column(

        children: <Widget>[
          StreamBuilder<String>(
            initialData: '',
            stream: _gameBloc.multiNetworkMessage,
            builder: (context, messageSnapshot){
                  return Text(messageSnapshot.data);
            },
          ),
          SizedBox(height: 40.0,),
          StreamBuilder<bool>(
            initialData: false,
            stream: _gameBloc.multiNetworkStarted,
            builder: (context, startedSnapshot){

                      return (startedSnapshot.data)? RaisedButton(child: Text('GO TO GAME'), onPressed: (){
                        Navigator.of(context).push(MaterialPageRoute(builder:(index)=> GameBoard()));
                      },) : Container();
            },
          )
        ],
      ),
    );
  }
}