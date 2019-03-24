import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:http/http.dart' as http;

class GameService{


  Future<bool> handleChallenge(User sender, User receiver, ChallengeHandleType handleType) async{


    String handleTypeString = handleType.toString().split('.').last; //remove from here...
    String url = 'https://us-central1-tic-tac-toe-a69ee.cloudfunctions.net/handleChallenge?senderId='+sender.id+'&senderName='+sender.name+'&senderFcmToken='+sender.fcmToken+'&receiverId='+receiver.id+'&receiverName='+receiver.name+'&receiverFcmToken='+receiver.fcmToken+'&handleType='+handleTypeString; 
    return _sendGetRequest(url);

  }

  Future<bool> playPiece(String gameId, String playerId, int position) async{

    String url = 'https://us-central1-tic-tac-toe-a69ee.cloudfunctions.net/playPiece?gameId='+gameId+'&playerId='+playerId+'&position='+position.toString();
    return _sendGetRequest(url);
}

 Future<bool> replayGame(String gameId, String playerId) async{

    String url = 'https://us-central1-tic-tac-toe-a69ee.cloudfunctions.net/replayGame?gameId='+gameId+'&playerId='+playerId;
    return _sendGetRequest(url);

}

Future<bool> cancelGame(String gameId, String playerId) async{

    String url = 'https://us-central1-tic-tac-toe-a69ee.cloudfunctions.net/cancelGame?gameId='+gameId+'&playerId='+playerId;
    return _sendGetRequest(url);


}


Future<bool> _sendGetRequest(String url) async{

   try{  
        final response =
          await http.get(url); 

        if (response.statusCode == 200) {
          return true;
        } else {
          throw Exception('error from server');
        }
    }catch(err){
        throw Exception('error while trying to repeat');
    }
}

}


