// lib/features/auth/data/auth_repository.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/features/auth/domain/user_session.dart';

class AuthRepository {
  final EmbyApiClient _apiClient;

  AuthRepository({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  /// Validate that the URL points to an Emby server.
  Future<ServerInfo> validateServer(String url) async {
    final data = await _apiClient.get(ApiEndpoints.publicSystemInfo);
    return ServerInfo.fromJson(data as Map<String, dynamic>, url);
  }

  /// Authenticate a user by username and password.
  Future<UserSession> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    final data = await _apiClient.post(
      ApiEndpoints.authenticateByName,
      data: {
        'Username': username,
        'Pw': password,
      },
    );

    final session = UserSession.fromAuthResponse(
      data as Map<String, dynamic>,
      serverUrl,
    );

    _apiClient.authInterceptor.token = session.accessToken;
    return session;
  }

  /// Log out and clear auth state.
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } finally {
      _apiClient.authInterceptor.clearAuth();
    }
  }

  /// Restore a session from stored credentials.
  void restoreSession(UserSession session) {
    _apiClient.updateBaseUrl(session.serverUrl);
    _apiClient.authInterceptor.token = session.accessToken;
  }
}
