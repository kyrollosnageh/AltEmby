class UserSession {
  final String userId;
  final String userName;
  final String accessToken;
  final String serverId;
  final String serverUrl;

  const UserSession({
    required this.userId,
    required this.userName,
    required this.accessToken,
    required this.serverId,
    required this.serverUrl,
  });

  factory UserSession.fromAuthResponse(Map<String, dynamic> json, String serverUrl) {
    final user = json['User'] as Map<String, dynamic>;
    return UserSession(
      userId: user['Id'] as String,
      userName: user['Name'] as String,
      accessToken: json['AccessToken'] as String,
      serverId: json['ServerId'] as String,
      serverUrl: serverUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'accessToken': accessToken,
        'serverId': serverId,
        'serverUrl': serverUrl,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      accessToken: json['accessToken'] as String,
      serverId: json['serverId'] as String,
      serverUrl: json['serverUrl'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          serverId == other.serverId;

  @override
  int get hashCode => userId.hashCode ^ serverId.hashCode;
}
