enum UserState { available, playing, away, offline }

class User {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final UserState currentState;
  final String fcmToken;

  User(
      {this.id,
      this.name,
      this.email,
      this.avatarUrl,
      this.currentState,
      this.fcmToken});

  User copyWith({
    String id,
    String name,
    String email,
    String avatarUrl,
    UserState currentState,
    String fcmToken,
  }) {

    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentState: currentState ?? this.currentState,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
