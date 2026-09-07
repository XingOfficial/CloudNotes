class AppUser {
  final String id;
  final String email;
  final String nickname;

  AppUser({
    required this.id,
    required this.email,
    required this.nickname,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nickname: json['nickname'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
    };
  }

  String get displayName {
    if (nickname.isNotEmpty) return nickname;
    return email.split('@')[0];
  }
}
