import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:flutter_firebase_tic_tac_toe/models/User.dart';
import 'package:flutter_firebase_tic_tac_toe/models/app_error.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

class UserService {
  FirebaseAuth _auth;
  GoogleSignIn _googleSignIn;

  UserService() {
    _auth = FirebaseAuth.instance;
    _googleSignIn = GoogleSignIn();
  }

  Future<User> authenticateWithFaceBook() async {
    var facebookLogin = new FacebookLogin();
    var result = await facebookLogin.logInWithReadPermissions(['email']);

    switch (result.status) {
      case FacebookLoginStatus.loggedIn:
        FirebaseUser user = await _auth.signInWithFacebook(
            accessToken: result.accessToken.token);
        User loggedInUser = User(
            id: user.uid,
            email: user.email,
            name: user.displayName,
            avatarUrl: user.photoUrl);
        String fcmToken = await _getTokenFromStore();
        loggedInUser.copyWith(fcmToken: fcmToken);
        await _addUserToStore(loggedInUser);
        await _saveUserToPreference(loggedInUser);
        return loggedInUser;
        break;
      case FacebookLoginStatus.cancelledByUser:
        throw (AppError('Login Cancelled'));
        break;
      case FacebookLoginStatus.error:
        throw (AppError('Login Failed'));
        break;
    }

    return null;
  }

  Future<User> authenticateWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final FirebaseUser user = await _auth.signInWithGoogle(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      User loggedInUser = User(
          id: user.uid,
          email: user.email,
          name: user.displayName,
          avatarUrl: user.photoUrl);
        String fcmToken = await _getTokenFromStore();
        loggedInUser.copyWith(fcmToken: fcmToken);
      await _addUserToStore(loggedInUser);
      await _saveUserToPreference(loggedInUser);
      return loggedInUser;
    } catch (error) {
      throw (AppError('Error occured during google authentication'));
    }
  }

  Future<User> signUpWithEmailAndPassword(username, email, password) async {
    //TODO: remove all uncessary stuffs
    final FirebaseUser user = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    final FirebaseUser currentUser = await _auth.currentUser();
    UserUpdateInfo updateInfo = new UserUpdateInfo();
    updateInfo.displayName = username;
    //TODO: Make image upload possible
    updateInfo.photoUrl = '';
    await currentUser.updateProfile(updateInfo);
    assert(user.uid == currentUser.uid);
    return signInWithEmailAndPasword(email, password);
  }

  Future<User> signInWithEmailAndPasword(email, password) async {
    final FirebaseUser user = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    User loggedInUser = User(
        id: user.uid,
        email: user.email,
        name: user.displayName,
        avatarUrl: user.photoUrl);

        String fcmToken = await _getTokenFromStore();
        loggedInUser = loggedInUser.copyWith(fcmToken: fcmToken);
    await _addUserToStore(loggedInUser);
    await _saveUserToPreference(loggedInUser);
    return loggedInUser;
  }

  Future<Null> _addUserToStore(User user) async {

    await Firestore.instance
        .collection('users')
        .document(user.id)
        .setData({'email': user.email, 'displayName': user.name, 'fcmToken': user.fcmToken});
  }

  Future<Null> _saveUserToPreference(User loggedInUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', loggedInUser.id);
    await prefs.setString('user_name', loggedInUser.name);
    return null;
  }

  saveUserFcmTokenToPreference(String token) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  addUserTokenToStore(String userId, String fcmToken) async{
      await Firestore.instance
        .collection('users')
        .document(userId)
        .setData({'fcmToken': fcmToken}, merge: true);
  }


  Future<String> _getTokenFromStore() async{ 
       SharedPreferences prefs = await SharedPreferences.getInstance();
       String fcmToken = prefs.getString('fcm_token');
       return fcmToken;
  }

  Future<User> getCurrentUser() async {

         SharedPreferences prefs = await SharedPreferences.getInstance();
         String   token = prefs.getString('fcm_token');
          String id = prefs.getString('user_id');
          String name = prefs.getString('user_name');

          return User(id: id, name: name, fcmToken:  token );

  }

  checkUserPresence(){

      FirebaseDatabase.instance
      .reference()
      .child('.info/connected')
      .onValue.listen((Event event) async{

        if(event.snapshot.value == false){
          return;
        }

          //TODONOW: check if user is available
          User currentUser = await getCurrentUser();
          FirebaseDatabase.instance.reference().child('/status/'+currentUser.id).onDisconnect().set({
            'state': 'offline'
          }).then((onValue){
              FirebaseDatabase.instance.reference().child('/status/'+currentUser.id).set({
                'state': 'available'
              });
          });
      });
  }
}
