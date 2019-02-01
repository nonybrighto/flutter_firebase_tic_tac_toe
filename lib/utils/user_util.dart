import 'package:flutter_firebase_tic_tac_toe/models/User.dart';

class UserUtil{

  getStateFromString(String userStateString){

      UserState state =UserState.values.firstWhere((userState) => userState.toString().split('.')[1] == userStateString);
      return state;
  }
}