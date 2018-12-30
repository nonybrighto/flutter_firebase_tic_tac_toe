enum  UserState{
  available, playing , away, offline
}

class User{
  final String id;
  final String name;
  final String avatarUrl;
  final UserState currentState;

  User({this.id, this.name, this.avatarUrl, this.currentState});
}