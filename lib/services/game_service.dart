import 'package:flutter_firebase_tic_tac_toe/models/game.dart';
import 'package:http/http.dart' as http;

class GameService{


  handleChallenge(String senderId, String senderName, String senderFcmToken, String receiverId, String receiverName, String receiverFcmToken, ChallengeHandleType handleType) async{

    
    // final response = await CloudFunctions.instance.call(functionName:'helloWorld', parameters:{'name': 'John'});
    // print(response);

    String handleTypeString = handleType.toString().split('.').last;

    String url = 'https://us-central1-tic-tac-toe-a69ee.cloudfunctions.net/handleChallenge?senderId='+senderId+'&senderName='+senderName+'&senderFcmToken='+senderFcmToken+'&receiverId='+receiverId+'&receiverName='+receiverName+'&receiverFcmToken='+receiverFcmToken+'&handleType='+handleTypeString;
    
    final response =
      await http.get(url); 

  if (response.statusCode == 200) {
    // If server returns an OK response, parse the JSON
    return true;

  } else {
    // If that response was not OK, throw an error.
    throw Exception('Could not send challenge');
  }


  }
}