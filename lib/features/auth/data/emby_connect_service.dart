import 'package:dio/dio.dart';
import 'package:altemby/core/constants/app_constants.dart';
import 'package:altemby/core/error/app_exceptions.dart';

class ConnectServer {
  final String systemId;
  final String accessKey;
  final String name;
  final String? remoteUrl;
  final String? localUrl;

  const ConnectServer({
    required this.systemId,
    required this.accessKey,
    required this.name,
    this.remoteUrl,
    this.localUrl,
  });

  List<String> get urls => [localUrl, remoteUrl].whereType<String>().toList();

  factory ConnectServer.fromJson(Map<String, dynamic> json) => ConnectServer(
        systemId: json['SystemId'] as String? ?? '',
        accessKey: json['AccessKey'] as String? ?? '',
        name: json['Name'] as String? ?? 'Emby Server',
        remoteUrl: json['Url'] as String?,
        localUrl: json['LocalAddress'] as String?,
      );
}

class ConnectUser {
  final String id;
  final String name;
  final String accessToken;

  const ConnectUser({
    required this.id,
    required this.name,
    required this.accessToken,
  });
}

class ConnectExchangeResult {
  final String localUserId;
  final String accessToken;
  final String serverUrl;

  const ConnectExchangeResult({
    required this.localUserId,
    required this.accessToken,
    required this.serverUrl,
  });
}

class EmbyConnectService {
  static const _baseUrl = 'https://connect.emby.media';
  final Dio _dio;
  // Reusable Dio for server exchange calls (no fixed baseUrl)
  final Dio _serverDio;

  EmbyConnectService()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'X-Application':
                '${AppConstants.appName}/${AppConstants.appVersion}',
            'Content-Type': 'application/json',
          },
        )),
        _serverDio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<ConnectUser> authenticate({
    required String nameOrEmail,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/service/user/authenticate', data: {
        'nameOrEmail': nameOrEmail,
        'rawpw': password,
      });
      final data = response.data as Map<String, dynamic>;
      final user = data['User'] as Map<String, dynamic>;
      return ConnectUser(
        id: user['Id'] as String,
        name: user['Name'] as String? ?? nameOrEmail,
        accessToken: data['AccessToken'] as String,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthenticationException('Invalid Emby Connect credentials',
            userMessage: 'Invalid email or password.');
      }
      throw const NetworkException('Could not reach Emby Connect',
          userMessage:
              'Could not connect to Emby Connect. Check your internet connection.');
    }
  }

  Future<List<ConnectServer>> getServers({
    required String connectUserId,
    required String connectAccessToken,
  }) async {
    try {
      final response = await _dio.get(
        '/service/servers',
        queryParameters: {'userId': connectUserId},
        options: Options(headers: {'X-Connect-UserToken': connectAccessToken}),
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ConnectServer.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      throw const NetworkException('Failed to fetch servers',
          userMessage: 'Could not retrieve your server list.');
    }
  }

  /// Tries all server URLs in parallel, returns the first successful exchange.
  Future<ConnectExchangeResult> exchangeTokenWithBestUrl({
    required ConnectServer server,
    required String connectUserId,
    required String deviceId,
    required String deviceName,
  }) async {
    final urls = server.urls;
    if (urls.isEmpty) {
      throw const NetworkException('No server URLs available',
          userMessage: 'This server has no reachable address.');
    }

    // Race all URLs in parallel -- first success wins
    final futures = urls.map((url) => _exchangeToken(
          serverUrl: url,
          connectUserId: connectUserId,
          accessKey: server.accessKey,
          deviceId: deviceId,
          deviceName: deviceName,
        ));

    // Collect results; return first success or throw last error
    Object? lastError;
    for (final future in futures) {
      try {
        return await future;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError is AppException
        ? lastError
        : const NetworkException('Could not reach server',
            userMessage: 'Could not reach the server to exchange credentials.');
  }

  Future<ConnectExchangeResult> _exchangeToken({
    required String serverUrl,
    required String connectUserId,
    required String accessKey,
    required String deviceId,
    required String deviceName,
  }) async {
    try {
      final response = await _serverDio.get(
        '$serverUrl/emby/Connect/Exchange',
        queryParameters: {
          'format': 'json',
          'ConnectUserId': connectUserId,
        },
        options: Options(headers: {
          'X-MediaBrowser-Token': accessKey,
          'X-Emby-Authorization':
              'MediaBrowser Client="${AppConstants.appName}", Device="$deviceName", DeviceId="$deviceId", Version="${AppConstants.appVersion}"',
        }),
      );
      final data = response.data as Map<String, dynamic>;
      return ConnectExchangeResult(
        localUserId: data['LocalUserId'] as String,
        accessToken: data['AccessToken'] as String,
        serverUrl: serverUrl,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthenticationException('Server rejected Connect token',
            userMessage:
                'This server did not accept your Emby Connect account.');
      }
      throw NetworkException('Could not connect to server: ${e.message}',
          userMessage: 'Could not reach the server to exchange credentials.');
    }
  }
}
