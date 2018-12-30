import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UsersBoard extends StatefulWidget {
  UsersBoard({Key key}) : super(key: key);

  @override
  _UsersBoardState createState() => new _UsersBoardState();
}

class _UsersBoardState extends State<UsersBoard> {

  List<User> users = [
        User(id:'aaa', name: 'Nony', avatarUrl: 'dd', currentState: UserState.available,),
        User(id:'aab', name: 'Mary', avatarUrl: 'dd', currentState: UserState.available,),
        User(id:'aac', name: 'Amaka', avatarUrl: 'dd', currentState: UserState.playing,),
        User(id:'aad', name: 'Chigo', avatarUrl: 'dd', currentState: UserState.away,),
        User(id:'aae', name: 'Ike', avatarUrl: 'dd', currentState: UserState.offline,),
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0XFF212845),
        title: Text('Tic Tac Toe users'),
      ),
      backgroundColor: Color(0XFF212845),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index,){
             
             return _userTile(users[index]);

      }),
    );
  }


  _userTile(User user){

    return InkWell(
      highlightColor: Color(0XFFF8D320),
          child: ListTile(leading: CircleAvatar(
        child: Text(user.name.substring(0,1)),
      ),
      title: Text(user.name, style: TextStyle(color:  Colors.white, fontSize: 23.0),),
      trailing: _userStateDisplay(user.currentState),  
      ),
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