import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/auth_page.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/bloc_provider.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/game_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/bloc/user_bloc.dart';
import 'package:flutter_firebase_tic_tac_toe/game_process_page.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsersBoard extends StatefulWidget {
  UsersBoard({Key key}) : super(key: key);

  @override
  _UsersBoardState createState() => new _UsersBoardState();
}

class _UsersBoardState extends State<UsersBoard> {

  UserBloc _userBloc;
  GameBloc _gameBloc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userBloc = BlocProvider.of<UserBloc>(context);
    _gameBloc = BlocProvider.of<GameBloc>(context);

  }
  
  @override
  Widget build(BuildContext context) {


    return StreamBuilder<User>(
      stream: _userBloc.currentUser,
      builder: (context, currentUserSnapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Tic Tac Toe users'),
          ),
          body: StreamBuilder(
            initialData: [],
            stream: _userBloc.users,
            builder: (context, usersSnapshot){
              return ListView.builder(
            itemCount: usersSnapshot.data.length,
            itemBuilder: (context, index,){
                 return _userTile(usersSnapshot.data[index], currentUserSnapshot.data);
          });
            },
          ),
        );
      }
    );
  }


  _userTile(User user, User currentUser){

    return InkWell(
      highlightColor: Color(0XFFF8D320),
          child: ListTile(leading: CircleAvatar(
        child: Text(user.name.substring(0,1)),
      ),
      title: Text(user.name, style: TextStyle(color:  Colors.white, fontSize: 23.0),),
      trailing: _userStateDisplay(user.currentState),  
      ),
      onTap: (){
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Send Challenge'),
                content: Text('Do you want to challenge '+user.name),
                actions: <Widget>[
                  FlatButton(
                    child: Text('CHALLENGE'),
                    onPressed: () async{
                        if(currentUser != null){
                          _gameBloc.handleChallenge(user, ChallengeHandleType.challenge);
                          Navigator.pop(context);
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => GameProcessPage()));
                        }else{
                             Navigator.of(context).push(MaterialPageRoute(
                                    builder: (index) => AuthPage(false)));
                        }
                    },
                  ),
                  FlatButton(
                    child: Text('DECLINE'),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  )
                ],
          ),
        );
      },
    );
  }

  _userStateDisplay(UserState userState){

    switch (userState) {
      case UserState.playing:
        return Icon(FontAwesomeIcons.gamepad, color: Colors.green,);
        break;
      case UserState.away:
        return _userStateCircle(Colors.amber);
        break;
      case UserState.available:
        return _userStateCircle(Colors.green);
      break;
      case UserState.offline:
      default:
        return _userStateCircle(Colors.grey);
         
    }
  }

  _userStateCircle(Color color){
         return CircleAvatar(
            backgroundColor: color,
            radius: 10.0,
          );
  }
}