class ServerInfo {
  final String url;
  final String serverName;
  final String serverId;
  final String version;

  const ServerInfo({
    required this.url,
    required this.serverName,
    required this.serverId,
    required this.version,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json, String url) {
    return ServerInfo(
      url: url,
      serverName: json['ServerName'] as String? ?? 'Emby Server',
      serverId: json['Id'] as String? ?? '',
      version: json['Version'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerInfo &&
          runtimeType == other.runtimeType &&
          serverId == other.serverId &&
          url == other.url;

  @override
  int get hashCode => serverId.hashCode ^ url.hashCode;
}
