import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:altemby/features/auth/domain/user_session.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({required FlutterSecureStorage storage})
      : _storage = storage;

  // Active session

  Future<void> saveSession(UserSession session) async {
    await _storage.write(
      key: 'active_session',
      value: jsonEncode(session.toJson()),
    );
  }

  Future<UserSession?> loadSession() async {
    final raw = await _storage.read(key: 'active_session');
    if (raw == null) return null;
    return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'active_session');
  }

  // Saved sessions (multi-user)

  Future<void> saveSessions(List<UserSession> sessions) async {
    final json = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _storage.write(key: 'saved_sessions', value: json);
  }

  Future<List<UserSession>> loadSavedSessions() async {
    final raw = await _storage.read(key: 'saved_sessions');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => UserSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addSavedSession(UserSession session) async {
    final sessions = await loadSavedSessions();
    sessions.removeWhere(
        (s) => s.userId == session.userId && s.serverId == session.serverId);
    sessions.add(session);
    await saveSessions(sessions);
  }

  Future<void> removeSavedSession(String userId, String serverId) async {
    final sessions = await loadSavedSessions();
    sessions.removeWhere(
        (s) => s.userId == userId && s.serverId == serverId);
    await saveSessions(sessions);
  }

  // Server URL

  Future<void> saveServerUrl(String url) async {
    await _storage.write(key: 'server_url', value: url);
  }

  Future<String?> loadServerUrl() async {
    return _storage.read(key: 'server_url');
  }
}
