import 'dart:async';

import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserBloc{


  final _currentUserSubject = BehaviorSubject<User>(seedValue: null);
  final _usersSubject = BehaviorSubject<List<User>>(seedValue: []);
  final _getUsersSubject = BehaviorSubject<Null>(seedValue: null);


  Stream<User> get currentUser => _currentUserSubject.stream;


  Stream<List<User>> get users => _usersSubject.stream;

  Function() get getUsers => () => _getUsersSubject.sink.add(null);

  Function(User) get changeCurrentUser => (user) => _currentUserSubject.sink.add(user);

  UserBloc(){


   _getUsersSubject.stream.listen((_){
          
          Firestore.instance.collection('users').snapshots().listen((data){

               List<User> users = data.documents.map((userSnapshot) => User(
                 id: userSnapshot.documentID,
                 name: userSnapshot['displayName'],
                 email: null,
                 avatarUrl: null,
                 currentState: UserState.available
               )).toList(); 

               _usersSubject.sink.add(users);
          });

   });

  }


  close(){
    _currentUserSubject.close();
    _getUsersSubject.close();
    _getUsersSubject.close();
    _usersSubject.close();
  }
}