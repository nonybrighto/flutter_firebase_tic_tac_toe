enum  UserState{
  available, playing , away, offline
}

class User{
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserState currentState;

  User({this.id, this.name, this.email, this.avatarUrl, this.currentState});
}