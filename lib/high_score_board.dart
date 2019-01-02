import 'package:flutter/material.dart';
import 'package:flutter_firebase_tic_tac_toe/models/score_detail.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';

class HighScoreBoard extends StatefulWidget {
  HighScoreBoard({Key key}) : super(key: key);

  @override
  _HighScoreBoardState createState() => new _HighScoreBoardState();
}

class _HighScoreBoardState extends State<HighScoreBoard> {


  List<ScoreDetail>  highScores = [
         ScoreDetail(user: User(id: 'hello', name: 'john'), losses: 10, wins: 90, wonLast: true),
         ScoreDetail(user: User(id: 'helloa', name: 'john'), losses: 12, wins: 20, wonLast: false),
         ScoreDetail(user: User(id: 'hello', name: 'john doe'), losses: 4, wins: 10, wonLast: false),
         ScoreDetail(user: User(id: 'hello', name: 'john alan'), losses: 10, wins: 19, wonLast: true),
         ScoreDetail(user: User(id: 'hello', name: 'john'), losses: 10, wins: 19, wonLast: true),
         ScoreDetail(user: User(id: 'hello', name: 'john'), losses: 10, wins: 19, wonLast: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(title: Text('High Score'),),
       body: ListView.builder(
         itemCount: (highScores == null)? 1 : highScores.length+1,
         itemBuilder: (context , index){
           if(index == 0){
             return Padding(
               padding: const EdgeInsets.fromLTRB(12.0, 5.0, 12.0, 5.0),
               child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: _titleText('User')),
                  Expanded(child:_titleText('Wins')),
                  Expanded(child:_titleText('Losses')),
                  Expanded(child:_titleText('Last Game')),
               ],),
             );
           }
           index -= 1;
           return _buildDetailBox(highScores[index]);
         },
       )
    );
  }
}

_titleText(String title){
  return Text(title, style: TextStyle(
      fontWeight: FontWeight.bold, fontSize: 15.0
  ),);
}

_buildDetailBox(ScoreDetail highScoreDetial){

  TextStyle fontStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16.0
  );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12.0, 5.0, 12.0, 5.0),
      child: Row(
        
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[

           Expanded(
             flex: 2,
                        child: Row(children: <Widget>[
                CircleAvatar(
                child: Text(highScoreDetial.user.name.substring(0,1),),
              ),
              SizedBox(width: 10.0,),
              Text(highScoreDetial.user.name, style: fontStyle,),
             ],),
           ),

          Expanded(child: Text(highScoreDetial.wins.toString() , style: fontStyle,)),
          Expanded(child: Text(highScoreDetial.losses.toString(), style: fontStyle,)),
          Expanded(
            child: _buildLastGameIcon(highScoreDetial.wonLast),
          )

      ],),
    );
}

_buildLastGameIcon(bool wonLast){

  return (wonLast)?Icon(Icons.arrow_drop_up, color: Colors.green,):
  Icon(Icons.arrow_drop_down, color: Colors.red,);
}