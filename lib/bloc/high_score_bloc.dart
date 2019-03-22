import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/score_detail.dart';
import 'package:rxdart/rxdart.dart';

class HighScoreBloc{

 final _highscores  = BehaviorSubject<List<ScoreDetail>>(seedValue:  []);
 final _fetchHighScores = BehaviorSubject<Null>();


  Function() get fetchHighScores => () => _fetchHighScores.sink.add(null);


  Stream<List<ScoreDetail>> get highScores => _highscores.stream;


  HighScoreBloc(){
    _fetchHighScores.stream.listen(_handleFetchHighScores);
  }

  _handleFetchHighScores(_){
        List<ScoreDetail> highScores = [];
       Firestore.instance.collection('scores').
       orderBy('wins', descending: true).limit(10).snapshots().listen((scoreSnapshot) async{

          if(scoreSnapshot.documents.isNotEmpty){
            for(int i = 0 ; i < scoreSnapshot.documents.length; i++){
               DocumentSnapshot userDoc =  await Firestore.instance.collection('users').document(scoreSnapshot.documents[i].documentID).get();
               final userDetails = userDoc.data;
               final scoreDetails = scoreSnapshot.documents[i].data;
               highScores.add(ScoreDetail(user: User(id: userDoc.documentID, name: userDetails['displayName']), losses: scoreDetails['losses'], wins: scoreDetails['wins'], wonLast: scoreDetails['wonLast']));    
            }
            _highscores.sink.add(highScores);
          }
       })..onError((err){
         print(err);
       });  
  }


  close(){
    _highscores.close();
    _fetchHighScores.close();
  }

}