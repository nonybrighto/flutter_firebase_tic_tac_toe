import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/services/user_service.dart';
import 'package:flutter_firebase_tic_tac_toe/utils/user_util.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBloc{

  final UserService userService;

  final _currentUserSubject = BehaviorSubject<User>(seedValue: User(id: null));
  final _usersSubject = BehaviorSubject<List<User>>(seedValue: []);
  final _getUsersSubject = BehaviorSubject<Null>(seedValue: null);
  final _changeFcmTokenSubject = BehaviorSubject<String>(seedValue: null);


  Stream<User> get currentUser => _currentUserSubject.stream;


  Stream<List<User>> get users => _usersSubject.stream;

  Function() get getUsers => () => _getUsersSubject.sink.add(null);

  Function(User) get changeCurrentUser => (user) => _currentUserSubject.sink.add(user);
  Function(String) get changeFcmToken => (token) => _changeFcmTokenSubject.sink.add(token);

  UserBloc({this.userService}){

    userService.checkUserPresence();

   _getUsersSubject.stream.listen((_){
          
          Firestore.instance.collection('users').snapshots().listen((data){

               List<User> users = data.documents.map((userSnapshot) => User(
                 id: userSnapshot.documentID,
                 name: userSnapshot['displayName'],
                 email: null,
                 avatarUrl: null,
                 fcmToken: userSnapshot['fcmToken'],
                 currentState: UserUtil().getStateFromString(userSnapshot['currentState'])
               )).toList(); 
               _usersSubject.sink.add(users);
          });

   });

   _changeFcmTokenSubject.withLatestFrom(_currentUserSubject, (token, currentUser){

      return {'token': token, 'currentUser': currentUser};
   }).listen((details){

          String token = details['token'];
          User currentUser = details['currentUser'];

          if(currentUser.id != null){
            currentUser = currentUser.copyWith(fcmToken: token);
            _currentUserSubject.sink.add(currentUser);
            userService.addUserTokenToStore(currentUser.id, token);
          }

          userService.saveUserFcmTokenToPreference(token);


   });  

  }


  close(){
    _currentUserSubject.close();
    _getUsersSubject.close();
    _getUsersSubject.close();
    _usersSubject.close();
  }
}