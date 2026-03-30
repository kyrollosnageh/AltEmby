# Phase 1 -- Foundation: Project Setup, API Client, Authentication

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a working Flutter app that can connect to an Emby server, authenticate a user, store credentials securely, and support multi-user profile switching -- all navigable and tested.

**Architecture:** Clean architecture with feature-based folders. Riverpod for state, Dio for networking with interceptors, GoRouter for navigation with auth guards, Flutter Secure Storage for tokens.

**Tech Stack:** Flutter/Dart, Riverpod, Dio, GoRouter, Flutter Secure Storage, Hive, device_info_plus

---

## File Structure

```
lib/
├── main.dart                                  # App entry, Hive init, ProviderScope, router
├── core/
│   ├── api/
│   │   ├── emby_api_client.dart               # Dio instance, base URL, interceptors
│   │   ├── emby_auth_interceptor.dart         # Adds X-Emby-Authorization header to every request
│   │   └── api_endpoints.dart                 # Static endpoint path constants
│   ├── constants/
│   │   └── app_constants.dart                 # App name, version, client ID
│   ├── error/
│   │   └── app_exceptions.dart                # ServerUnreachableException, AuthException, etc.
│   └── utils/
│       └── device_utils.dart                  # Generate/persist device ID, detect Android TV
├── features/
│   └── auth/
│       ├── data/
│       │   ├── auth_repository.dart           # Calls Emby auth endpoints, wraps responses
│       │   └── secure_storage_service.dart    # Read/write tokens and server URL
│       ├── domain/
│       │   ├── server_info.dart               # ServerInfo model (name, url, version, id)
│       │   └── user_session.dart              # UserSession model (userId, userName, token, serverId)
│       └── presentation/
│           ├── providers/
│           │   └── auth_providers.dart        # Riverpod providers: authState, serverInfo, etc.
│           ├── server_connect_screen.dart      # Enter server URL, validate
│           ├── login_screen.dart               # Username + password form
│           └── user_select_screen.dart         # Pick from saved profiles or add new
├── features/
│   └── home/
│       └── presentation/
│           └── home_screen.dart                # Placeholder home screen (Phase 2 builds this out)
└── app_router.dart                             # GoRouter config with auth redirect
test/
├── core/
│   └── api/
│       ├── emby_api_client_test.dart
│       └── emby_auth_interceptor_test.dart
├── features/
│   └── auth/
│       ├── data/
│       │   └── auth_repository_test.dart
│       └── presentation/
│           └── auth_providers_test.dart
└── widget/
    ├── server_connect_screen_test.dart
    ├── login_screen_test.dart
    └── user_select_screen_test.dart
```

---

### Task 1: Create Flutter Project and Configure Dependencies

**Files:**
- Create: `pubspec.yaml` (via `flutter create`)
- Modify: `pubspec.yaml` (add dependencies)
- Create: `analysis_options.yaml` (adjust lints)

- [ ] **Step 1: Create the Flutter project**

Run from the parent directory (`Documents`):

```bash
cd "c:/Users/kyrol/OneDrive/Documents"
flutter create --org com.altemby --project-name altemby --platforms android,ios "AltEmby"
```

This scaffolds the project in the existing `AltEmby` folder.

- [ ] **Step 2: Replace pubspec.yaml dependencies**

Replace the `dependencies` and `dev_dependencies` sections in `pubspec.yaml`:

```yaml
name: altemby
description: A lightweight Emby media streaming client.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.0

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.7.0
  flutter_riverpod: ^2.6.1
  go_router: ^14.8.1
  flutter_secure_storage: ^9.2.4
  hive_flutter: ^1.1.0
  device_info_plus: ^11.2.0
  connectivity_plus: ^6.1.1
  uuid: ^4.5.1
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.14
  freezed: ^2.5.8
  json_serializable: ^6.9.4
  mocktail: ^1.0.4

flutter:
  uses-material-design: true
```

- [ ] **Step 3: Get dependencies**

```bash
cd "c:/Users/kyrol/OneDrive/Documents/AltEmby"
flutter pub get
```

Expected: resolves successfully, no version conflicts.

- [ ] **Step 4: Verify project builds**

```bash
flutter analyze
```

Expected: no issues (the default template should be clean).

- [ ] **Step 5: Commit**

```bash
git init
git add .
git commit -m "chore: scaffold Flutter project with dependencies"
```

---

### Task 2: App Constants and Error Types

**Files:**
- Create: `lib/core/constants/app_constants.dart`
- Create: `lib/core/error/app_exceptions.dart`

- [ ] **Step 1: Create app constants**

```dart
// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName = 'AltEmby';
  static const String appVersion = '1.0.0';
  static const String clientId = 'com.altemby.app';

  // Storage keys
  static const String serverUrlKey = 'server_url';
  static const String accessTokenKey = 'access_token';
  static const String userIdKey = 'user_id';
  static const String deviceIdKey = 'device_id';
  static const String savedSessionsBox = 'saved_sessions';
}
```

- [ ] **Step 2: Create app exceptions**

```dart
// lib/core/error/app_exceptions.dart

sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class ServerUnreachableException extends AppException {
  const ServerUnreachableException(super.message);
}

class InvalidServerException extends AppException {
  const InvalidServerException(super.message);
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message);
}

class SessionExpiredException extends AppException {
  const SessionExpiredException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/core/
git commit -m "feat: add app constants and exception types"
```

---

### Task 3: Device Utilities (Device ID + TV Detection)

**Files:**
- Create: `lib/core/utils/device_utils.dart`
- Create: `test/core/utils/device_utils_test.dart`

- [ ] **Step 1: Write test for DeviceUtils**

```dart
// test/core/utils/device_utils_test.dart

import 'package:altemby/core/utils/device_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late DeviceUtils deviceUtils;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    deviceUtils = DeviceUtils(secureStorage: mockStorage);
  });

  group('getOrCreateDeviceId', () {
    test('returns existing device ID when stored', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => 'existing-id-123');

      final id = await deviceUtils.getOrCreateDeviceId();

      expect(id, 'existing-id-123');
      verifyNever(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')));
    });

    test('creates and stores new device ID when none exists', () async {
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final id = await deviceUtils.getOrCreateDeviceId();

      expect(id, isNotEmpty);
      expect(id.length, greaterThanOrEqualTo(32));
      verify(() => mockStorage.write(key: 'device_id', value: id)).called(1);
    });
  });

  group('getDeviceName', () {
    test('returns a non-empty string', () {
      final name = DeviceUtils.getDeviceName();
      expect(name, isNotEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/utils/device_utils_test.dart
```

Expected: FAIL -- `device_utils.dart` does not exist.

- [ ] **Step 3: Implement DeviceUtils**

```dart
// lib/core/utils/device_utils.dart

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceUtils {
  final FlutterSecureStorage _secureStorage;

  DeviceUtils({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: 'device_id');
    if (existing != null) return existing;

    final newId = const Uuid().v4();
    await _secureStorage.write(key: 'device_id', value: newId);
    return newId;
  }

  static String getDeviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Flutter Device';
    }
  }

  /// Checks for Android TV via system features.
  /// Must be called from Android only. Returns false on other platforms.
  static Future<bool> isAndroidTv() async {
    if (!Platform.isAndroid) return false;
    // Actual check requires device_info_plus; deferred to app startup.
    // This is a placeholder that will be wired up in main.dart.
    return false;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/utils/device_utils_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/ test/core/
git commit -m "feat: add DeviceUtils for device ID and name"
```

---

### Task 4: API Endpoint Constants

**Files:**
- Create: `lib/core/api/api_endpoints.dart`

- [ ] **Step 1: Create endpoint constants**

```dart
// lib/core/api/api_endpoints.dart

class ApiEndpoints {
  ApiEndpoints._();

  // Server info (no auth required)
  static const String publicSystemInfo = '/System/Info/Public';

  // Authentication
  static const String authenticateByName = '/Users/AuthenticateByName';
  static const String logout = '/Sessions/Logout';

  // Users
  static String publicUsers = '/Users/Public';

  // Library (user-scoped)
  static String userItems(String userId) => '/Users/$userId/Items';
  static String userItem(String userId, String itemId) =>
      '/Users/$userId/Items/$itemId';

  // Images
  static String itemImage(String itemId, String type, {int? index}) {
    if (index != null) return '/Items/$itemId/Images/$type/$index';
    return '/Items/$itemId/Images/$type';
  }

  // Playback
  static String videoStream(String itemId) => '/Videos/$itemId/stream';
  static String audioStream(String itemId) => '/Audio/$itemId/stream';
  static String fileDownload(String itemId) => '/Items/$itemId/File';

  // Session reporting
  static const String playbackStart = '/Sessions/Playing';
  static const String playbackProgress = '/Sessions/Playing/Progress';
  static const String playbackStopped = '/Sessions/Playing/Stopped';

  // TV Shows
  static String showSeasons(String seriesId) => '/Shows/$seriesId/Seasons';
  static String showEpisodes(String seriesId) => '/Shows/$seriesId/Episodes';
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/api/api_endpoints.dart
git commit -m "feat: add Emby API endpoint constants"
```

---

### Task 5: Emby Auth Interceptor

**Files:**
- Create: `lib/core/api/emby_auth_interceptor.dart`
- Create: `test/core/api/emby_auth_interceptor_test.dart`

- [ ] **Step 1: Write test for the interceptor**

```dart
// test/core/api/emby_auth_interceptor_test.dart

import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmbyAuthInterceptor', () {
    test('adds X-Emby-Authorization header without token when unauthenticated', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );

      final options = RequestOptions(path: '/test');
      // Simulate onRequest by calling the method
      bool nextCalled = false;
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, contains('Client="${AppConstants.appName}"'));
      expect(header, contains('Device="TestDevice"'));
      expect(header, contains('DeviceId="test-device-id"'));
      expect(header, contains('Version="${AppConstants.appVersion}"'));
      expect(header, isNot(contains('Token=')));
    });

    test('adds X-Emby-Authorization header with token when authenticated', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );
      interceptor.token = 'my-access-token';

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, contains('Token="my-access-token"'));
    });

    test('clears token on clearAuth', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-device-id',
        deviceName: 'TestDevice',
      );
      interceptor.token = 'my-access-token';
      interceptor.clearAuth();

      final options = RequestOptions(path: '/test');
      interceptor.onRequest(
        options,
        RequestInterceptorHandler(),
      );

      final header = options.headers['X-Emby-Authorization'] as String;
      expect(header, isNot(contains('Token=')));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/api/emby_auth_interceptor_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement the interceptor**

```dart
// lib/core/api/emby_auth_interceptor.dart

import 'package:dio/dio.dart';
import 'package:altemby/core/constants/app_constants.dart';

class EmbyAuthInterceptor extends Interceptor {
  final String deviceId;
  final String deviceName;
  String? token;

  EmbyAuthInterceptor({
    required this.deviceId,
    required this.deviceName,
    this.token,
  });

  void clearAuth() {
    token = null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final parts = <String>[
      'Client="${AppConstants.appName}"',
      'Device="$deviceName"',
      'DeviceId="$deviceId"',
      'Version="${AppConstants.appVersion}"',
    ];

    if (token != null) {
      parts.add('Token="$token"');
    }

    options.headers['X-Emby-Authorization'] = 'MediaBrowser ${parts.join(', ')}';
    handler.next(options);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/api/emby_auth_interceptor_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/emby_auth_interceptor.dart test/core/api/
git commit -m "feat: add Emby auth interceptor for Dio"
```

---

### Task 6: Emby API Client

**Files:**
- Create: `lib/core/api/emby_api_client.dart`
- Create: `test/core/api/emby_api_client_test.dart`

- [ ] **Step 1: Write test for EmbyApiClient**

```dart
// test/core/api/emby_api_client_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/error/app_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {
  @override
  Interceptors get interceptors => Interceptors();

  @override
  BaseOptions get options => BaseOptions();

  @override
  set options(BaseOptions value) {}
}

void main() {
  group('EmbyApiClient', () {
    test('constructs with base URL and interceptor', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://emby.example.com',
        authInterceptor: interceptor,
      );

      expect(client.baseUrl, 'https://emby.example.com');
    });

    test('normalizes base URL by removing trailing slash', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://emby.example.com/',
        authInterceptor: interceptor,
      );

      expect(client.baseUrl, 'https://emby.example.com');
    });

    test('updateBaseUrl changes the Dio base URL', () {
      final interceptor = EmbyAuthInterceptor(
        deviceId: 'test-id',
        deviceName: 'Test',
      );
      final client = EmbyApiClient(
        baseUrl: 'https://old.example.com',
        authInterceptor: interceptor,
      );

      client.updateBaseUrl('https://new.example.com');

      expect(client.baseUrl, 'https://new.example.com');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/core/api/emby_api_client_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement EmbyApiClient**

```dart
// lib/core/api/emby_api_client.dart

import 'package:dio/dio.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/error/app_exceptions.dart';

class EmbyApiClient {
  final Dio _dio;
  final EmbyAuthInterceptor authInterceptor;
  String _baseUrl;

  String get baseUrl => _baseUrl;

  EmbyApiClient({
    required String baseUrl,
    required this.authInterceptor,
    Dio? dio,
  })  : _baseUrl = _normalizeUrl(baseUrl),
        _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.json,
    );
    _dio.interceptors.add(authInterceptor);
  }

  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void updateBaseUrl(String url) {
    _baseUrl = _normalizeUrl(url);
    _dio.options.baseUrl = _baseUrl;
  }

  /// GET request. Returns the response data.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST request. Returns the response data.
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// DELETE request. Returns the response data.
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Build a full URL for media streaming (used by the player).
  /// Appends the auth token as a query parameter since players can't set headers.
  String getStreamUrl(String path, {Map<String, dynamic>? queryParameters}) {
    final params = <String, dynamic>{
      'Static': 'true',
      if (authInterceptor.token != null) 'api_key': authInterceptor.token,
      ...?queryParameters,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$_baseUrl$path?$query';
  }

  AppException _mapDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        ServerUnreachableException('Connection timed out: ${e.message}'),
      DioExceptionType.connectionError =>
        ServerUnreachableException('Cannot reach server: ${e.message}'),
      DioExceptionType.badResponse => _mapStatusCode(e.response?.statusCode, e.message),
      _ => NetworkException('Network error: ${e.message}'),
    };
  }

  AppException _mapStatusCode(int? statusCode, String? message) {
    return switch (statusCode) {
      401 => const SessionExpiredException('Session expired. Please log in again.'),
      403 => const AuthenticationException('Access denied.'),
      404 => NetworkException('Not found: $message'),
      _ => NetworkException('Server error ($statusCode): $message'),
    };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/core/api/emby_api_client_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/api/emby_api_client.dart test/core/api/emby_api_client_test.dart
git commit -m "feat: add EmbyApiClient with Dio and error mapping"
```

---

### Task 7: Domain Models -- ServerInfo and UserSession

**Files:**
- Create: `lib/features/auth/domain/server_info.dart`
- Create: `lib/features/auth/domain/user_session.dart`

- [ ] **Step 1: Create ServerInfo model**

```dart
// lib/features/auth/domain/server_info.dart

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
```

- [ ] **Step 2: Create UserSession model**

```dart
// lib/features/auth/domain/user_session.dart

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
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/domain/
git commit -m "feat: add ServerInfo and UserSession domain models"
```

---

### Task 8: Secure Storage Service

**Files:**
- Create: `lib/features/auth/data/secure_storage_service.dart`
- Create: `test/features/auth/data/secure_storage_service_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/auth/data/secure_storage_service_test.dart

import 'dart:convert';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late SecureStorageService service;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    service = SecureStorageService(storage: mockStorage);
  });

  group('saveSession', () {
    test('saves session JSON to secure storage', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final session = UserSession(
        userId: 'u1',
        userName: 'TestUser',
        accessToken: 'token123',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );

      await service.saveSession(session);

      verify(() => mockStorage.write(
            key: 'active_session',
            value: jsonEncode(session.toJson()),
          )).called(1);
    });
  });

  group('loadSession', () {
    test('returns null when no session stored', () async {
      when(() => mockStorage.read(key: 'active_session'))
          .thenAnswer((_) async => null);

      final result = await service.loadSession();
      expect(result, isNull);
    });

    test('returns UserSession when stored', () async {
      final sessionJson = jsonEncode({
        'userId': 'u1',
        'userName': 'TestUser',
        'accessToken': 'token123',
        'serverId': 's1',
        'serverUrl': 'https://emby.test',
      });
      when(() => mockStorage.read(key: 'active_session'))
          .thenAnswer((_) async => sessionJson);

      final result = await service.loadSession();
      expect(result, isNotNull);
      expect(result!.userId, 'u1');
      expect(result.accessToken, 'token123');
    });
  });

  group('clearSession', () {
    test('deletes the active session', () async {
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      await service.clearSession();

      verify(() => mockStorage.delete(key: 'active_session')).called(1);
    });
  });

  group('savedSessions', () {
    test('saves and retrieves a list of sessions', () async {
      when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      final sessions = [
        UserSession(
          userId: 'u1',
          userName: 'User1',
          accessToken: 't1',
          serverId: 's1',
          serverUrl: 'https://emby.test',
        ),
      ];

      await service.saveSessions(sessions);

      verify(() => mockStorage.write(
            key: 'saved_sessions',
            value: jsonEncode(sessions.map((s) => s.toJson()).toList()),
          )).called(1);
    });

    test('returns empty list when no saved sessions', () async {
      when(() => mockStorage.read(key: 'saved_sessions'))
          .thenAnswer((_) async => null);

      final result = await service.loadSavedSessions();
      expect(result, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/auth/data/secure_storage_service_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement SecureStorageService**

```dart
// lib/features/auth/data/secure_storage_service.dart

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
    // Replace existing session for same user+server, or add new
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
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/auth/data/secure_storage_service_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/secure_storage_service.dart test/features/auth/data/
git commit -m "feat: add SecureStorageService for session persistence"
```

---

### Task 9: Auth Repository

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`
- Create: `test/features/auth/data/auth_repository_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/auth/data/auth_repository_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/error/app_exceptions.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

class MockEmbyAuthInterceptor extends Mock implements EmbyAuthInterceptor {}

void main() {
  late MockEmbyApiClient mockClient;
  late MockEmbyAuthInterceptor mockInterceptor;
  late AuthRepository repo;

  setUp(() {
    mockClient = MockEmbyApiClient();
    mockInterceptor = MockEmbyAuthInterceptor();
    when(() => mockClient.authInterceptor).thenReturn(mockInterceptor);
    repo = AuthRepository(apiClient: mockClient);
  });

  group('validateServer', () {
    test('returns ServerInfo on valid response', () async {
      when(() => mockClient.get('/System/Info/Public'))
          .thenAnswer((_) async => {
                'ServerName': 'My Emby',
                'Id': 'server-abc',
                'Version': '4.8.0.0',
              });

      final result = await repo.validateServer('https://emby.test');
      expect(result.serverName, 'My Emby');
      expect(result.serverId, 'server-abc');
      expect(result.version, '4.8.0.0');
      expect(result.url, 'https://emby.test');
    });

    test('throws ServerUnreachableException on failure', () async {
      when(() => mockClient.get('/System/Info/Public'))
          .thenThrow(const ServerUnreachableException('timeout'));

      expect(
        () => repo.validateServer('https://emby.test'),
        throwsA(isA<ServerUnreachableException>()),
      );
    });
  });

  group('login', () {
    test('returns UserSession on success', () async {
      when(() => mockClient.post(
            '/Users/AuthenticateByName',
            data: {'Username': 'admin', 'Pw': 'pass123'},
          )).thenAnswer((_) async => {
            'AccessToken': 'tok-abc',
            'ServerId': 'server-abc',
            'User': {
              'Id': 'user-1',
              'Name': 'admin',
            },
          });
      when(() => mockInterceptor.token = any(named: 'token')).thenReturn(null);

      final result = await repo.login(
        username: 'admin',
        password: 'pass123',
        serverUrl: 'https://emby.test',
      );

      expect(result.userId, 'user-1');
      expect(result.accessToken, 'tok-abc');
      expect(result.userName, 'admin');
      verify(() => mockInterceptor.token = 'tok-abc').called(1);
    });

    test('throws AuthenticationException on 401', () async {
      when(() => mockClient.post(
            '/Users/AuthenticateByName',
            data: {'Username': 'bad', 'Pw': 'wrong'},
          )).thenThrow(
              const AuthenticationException('Invalid username or password'));

      expect(
        () => repo.login(
          username: 'bad',
          password: 'wrong',
          serverUrl: 'https://emby.test',
        ),
        throwsA(isA<AuthenticationException>()),
      );
    });
  });

  group('logout', () {
    test('calls logout endpoint and clears token', () async {
      when(() => mockClient.post('/Sessions/Logout'))
          .thenAnswer((_) async => null);
      when(() => mockInterceptor.clearAuth()).thenReturn(null);

      await repo.logout();

      verify(() => mockClient.post('/Sessions/Logout')).called(1);
      verify(() => mockInterceptor.clearAuth()).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/auth/data/auth_repository_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement AuthRepository**

```dart
// lib/features/auth/data/auth_repository.dart

import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/features/auth/domain/user_session.dart';

class AuthRepository {
  final EmbyApiClient _apiClient;

  AuthRepository({required EmbyApiClient apiClient}) : _apiClient = apiClient;

  /// Validate that the URL points to an Emby server.
  /// Returns [ServerInfo] on success.
  Future<ServerInfo> validateServer(String url) async {
    final data = await _apiClient.get(ApiEndpoints.publicSystemInfo);
    return ServerInfo.fromJson(data as Map<String, dynamic>, url);
  }

  /// Authenticate a user by username and password.
  /// Sets the auth token on the interceptor on success.
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

  /// Log out the current session and clear auth state.
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } finally {
      _apiClient.authInterceptor.clearAuth();
    }
  }

  /// Restore a session from stored credentials.
  /// Sets the token on the interceptor.
  void restoreSession(UserSession session) {
    _apiClient.updateBaseUrl(session.serverUrl);
    _apiClient.authInterceptor.token = session.accessToken;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/auth/data/auth_repository_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/data/auth_repository.dart test/features/auth/data/auth_repository_test.dart
git commit -m "feat: add AuthRepository for server validation and login"
```

---

### Task 10: Riverpod Auth Providers

**Files:**
- Create: `lib/features/auth/presentation/providers/auth_providers.dart`
- Create: `test/features/auth/presentation/auth_providers_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/features/auth/presentation/auth_providers_test.dart

import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthNotifier', () {
    late MockSecureStorageService mockStorage;
    late MockAuthRepository mockRepo;
    late AuthNotifier notifier;

    setUp(() {
      mockStorage = MockSecureStorageService();
      mockRepo = MockAuthRepository();
      notifier = AuthNotifier(
        storageService: mockStorage,
        authRepository: mockRepo,
      );
    });

    test('initial state is unauthenticated', () {
      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('tryRestoreSession sets authenticated on stored session', () async {
      final session = UserSession(
        userId: 'u1',
        userName: 'Test',
        accessToken: 'tok',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );
      when(() => mockStorage.loadSession()).thenAnswer((_) async => session);
      when(() => mockRepo.restoreSession(session)).thenReturn(null);

      await notifier.tryRestoreSession();

      expect(
        notifier.state,
        AuthState.authenticated(session),
      );
    });

    test('tryRestoreSession stays unauthenticated when no session', () async {
      when(() => mockStorage.loadSession()).thenAnswer((_) async => null);

      await notifier.tryRestoreSession();

      expect(notifier.state, const AuthState.unauthenticated());
    });

    test('login sets authenticated on success', () async {
      final session = UserSession(
        userId: 'u1',
        userName: 'Test',
        accessToken: 'tok',
        serverId: 's1',
        serverUrl: 'https://emby.test',
      );
      when(() => mockRepo.login(
            username: 'admin',
            password: 'pass',
            serverUrl: 'https://emby.test',
          )).thenAnswer((_) async => session);
      when(() => mockStorage.saveSession(session)).thenAnswer((_) async {});
      when(() => mockStorage.addSavedSession(session)).thenAnswer((_) async {});

      await notifier.login(
        username: 'admin',
        password: 'pass',
        serverUrl: 'https://emby.test',
      );

      expect(notifier.state, AuthState.authenticated(session));
    });

    test('logout clears state', () async {
      when(() => mockRepo.logout()).thenAnswer((_) async {});
      when(() => mockStorage.clearSession()).thenAnswer((_) async {});

      await notifier.logout();

      expect(notifier.state, const AuthState.unauthenticated());
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/features/auth/presentation/auth_providers_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement auth providers**

```dart
// lib/features/auth/presentation/providers/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/core/api/emby_auth_interceptor.dart';
import 'package:altemby/core/utils/device_utils.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/features/auth/domain/user_session.dart';

// --- Auth State ---

sealed class AuthState {
  const AuthState();
  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.authenticated(UserSession session) = Authenticated;
  const factory AuthState.loading() = AuthLoading;
}

class Unauthenticated extends AuthState {
  const Unauthenticated();

  @override
  bool operator ==(Object other) => other is Unauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

class Authenticated extends AuthState {
  final UserSession session;
  const Authenticated(this.session);

  @override
  bool operator ==(Object other) =>
      other is Authenticated && other.session == session;

  @override
  int get hashCode => session.hashCode;
}

class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  bool operator ==(Object other) => other is AuthLoading;

  @override
  int get hashCode => runtimeType.hashCode;
}

// --- Core Service Providers ---

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(storage: ref.watch(secureStorageProvider)),
);

final deviceUtilsProvider = Provider<DeviceUtils>(
  (ref) => DeviceUtils(secureStorage: ref.watch(secureStorageProvider)),
);

final embyAuthInterceptorProvider = Provider<EmbyAuthInterceptor>(
  (ref) => EmbyAuthInterceptor(
    deviceId: '', // Will be initialized at app start
    deviceName: DeviceUtils.getDeviceName(),
  ),
);

final embyApiClientProvider = Provider<EmbyApiClient>(
  (ref) => EmbyApiClient(
    baseUrl: 'http://localhost', // Will be updated when server is set
    authInterceptor: ref.watch(embyAuthInterceptorProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(apiClient: ref.watch(embyApiClientProvider)),
);

// --- Server Info ---

final serverInfoProvider = StateProvider<ServerInfo?>((ref) => null);

// --- Auth Notifier ---

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    storageService: ref.watch(secureStorageServiceProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storageService;
  final AuthRepository _authRepository;

  AuthNotifier({
    required SecureStorageService storageService,
    required AuthRepository authRepository,
  })  : _storageService = storageService,
        _authRepository = authRepository,
        super(const AuthState.unauthenticated());

  Future<void> tryRestoreSession() async {
    state = const AuthState.loading();
    final session = await _storageService.loadSession();
    if (session != null) {
      _authRepository.restoreSession(session);
      state = AuthState.authenticated(session);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    state = const AuthState.loading();
    final session = await _authRepository.login(
      username: username,
      password: password,
      serverUrl: serverUrl,
    );
    await _storageService.saveSession(session);
    await _storageService.addSavedSession(session);
    state = AuthState.authenticated(session);
  }

  Future<void> switchToSession(UserSession session) async {
    state = const AuthState.loading();
    _authRepository.restoreSession(session);
    await _storageService.saveSession(session);
    state = AuthState.authenticated(session);
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } finally {
      await _storageService.clearSession();
      state = const AuthState.unauthenticated();
    }
  }
}

// --- Saved Sessions ---

final savedSessionsProvider = FutureProvider<List<UserSession>>((ref) async {
  final storage = ref.watch(secureStorageServiceProvider);
  return storage.loadSavedSessions();
});
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/features/auth/presentation/auth_providers_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/providers/ test/features/auth/presentation/
git commit -m "feat: add Riverpod auth providers and AuthNotifier"
```

---

### Task 11: Server Connect Screen

**Files:**
- Create: `lib/features/auth/presentation/server_connect_screen.dart`
- Create: `test/widget/server_connect_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/server_connect_screen_test.dart

import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockEmbyApiClient extends Mock implements EmbyApiClient {}

void main() {
  group('ServerConnectScreen', () {
    testWidgets('shows text field and connect button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('shows error when URL is empty and connect pressed',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      await tester.tap(find.text('Connect'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a server URL'), findsOneWidget);
    });

    testWidgets('shows HTTPS warning for HTTP URLs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ServerConnectScreen()),
        ),
      );

      await tester.enterText(find.byType(TextField), 'http://192.168.1.100:8096');
      await tester.pumpAndSettle();

      expect(find.textContaining('not using HTTPS'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/server_connect_screen_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement ServerConnectScreen**

```dart
// lib/features/auth/presentation/server_connect_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/features/auth/data/auth_repository.dart';
import 'package:altemby/features/auth/domain/server_info.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class ServerConnectScreen extends ConsumerStatefulWidget {
  const ServerConnectScreen({super.key});

  @override
  ConsumerState<ServerConnectScreen> createState() =>
      _ServerConnectScreenState();
}

class _ServerConnectScreenState extends ConsumerState<ServerConnectScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isConnecting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _isHttpUrl {
    final text = _urlController.text.trim().toLowerCase();
    return text.startsWith('http://');
  }

  String _normalizeUrl(String input) {
    var url = input.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<void> _connect() async {
    setState(() => _errorMessage = null);

    if (_urlController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a server URL');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final url = _normalizeUrl(_urlController.text);

    setState(() => _isConnecting = true);

    try {
      final apiClient = ref.read(embyApiClientProvider);
      apiClient.updateBaseUrl(url);

      final repo = ref.read(authRepositoryProvider);
      final serverInfo = await repo.validateServer(url);

      if (!mounted) return;

      ref.read(serverInfoProvider.notifier).state = serverInfo;

      // Store the server URL
      final storage = ref.read(secureStorageServiceProvider);
      await storage.saveServerUrl(url);

      if (!mounted) return;

      // Navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not connect to server: $e';
        _isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AltEmby',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect to your Emby server',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://emby.example.com:8096',
                      prefixIcon: const Icon(Icons.dns),
                      border: const OutlineInputBorder(),
                      errorText: _errorMessage,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _connect(),
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_isHttpUrl) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'You are not using HTTPS. Your connection is not secure.',
                            style: TextStyle(color: Colors.orange[700], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isConnecting ? null : _connect,
                      child: _isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Connect'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/server_connect_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/server_connect_screen.dart test/widget/
git commit -m "feat: add ServerConnectScreen with URL validation"
```

---

### Task 12: Login Screen

**Files:**
- Create: `lib/features/auth/presentation/login_screen.dart`
- Create: `test/widget/login_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/login_screen_test.dart

import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows username and password fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('shows sign in button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows error when username is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your username'), findsOneWidget);
    });

    testWidgets('password visibility toggles', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LoginScreen()),
        ),
      );

      // Find the visibility toggle icon
      final visibilityIcon = find.byIcon(Icons.visibility_off);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/login_screen_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement LoginScreen**

```dart
// lib/features/auth/presentation/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _usernameError;
  String? _loginError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _usernameError = null;
      _loginError = null;
    });

    if (_usernameController.text.trim().isEmpty) {
      setState(() => _usernameError = 'Please enter your username');
      return;
    }

    final serverInfo = ref.read(serverInfoProvider);
    if (serverInfo == null) {
      setState(() => _loginError = 'No server configured. Go back and connect first.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authNotifierProvider.notifier).login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            serverUrl: serverInfo.url,
          );
      // Navigation happens via auth state listener in the router
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loginError = 'Login failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverInfo = ref.watch(serverInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (serverInfo != null) ...[
                  Text(
                    serverInfo.serverName,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serverInfo.url,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    errorText: _usernameError,
                  ),
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _login(),
                ),
                if (_loginError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _loginError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/login_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/login_screen.dart test/widget/login_screen_test.dart
git commit -m "feat: add LoginScreen with username/password auth"
```

---

### Task 13: User Select Screen (Multi-User Profile Picker)

**Files:**
- Create: `lib/features/auth/presentation/user_select_screen.dart`
- Create: `test/widget/user_select_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/widget/user_select_screen_test.dart

import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/data/secure_storage_service.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('UserSelectScreen', () {
    testWidgets('shows "Add Account" button', (tester) async {
      final mockStorage = MockSecureStorageService();
      when(() => mockStorage.loadSavedSessions()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(home: UserSelectScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Account'), findsOneWidget);
    });

    testWidgets('shows saved user profiles', (tester) async {
      final mockStorage = MockSecureStorageService();
      when(() => mockStorage.loadSavedSessions()).thenAnswer((_) async => [
            UserSession(
              userId: 'u1',
              userName: 'Alice',
              accessToken: 't1',
              serverId: 's1',
              serverUrl: 'https://emby.test',
            ),
            UserSession(
              userId: 'u2',
              userName: 'Bob',
              accessToken: 't2',
              serverId: 's1',
              serverUrl: 'https://emby.test',
            ),
          ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
          child: const MaterialApp(home: UserSelectScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
flutter test test/widget/user_select_screen_test.dart
```

Expected: FAIL -- file not found.

- [ ] **Step 3: Implement UserSelectScreen**

```dart
// lib/features/auth/presentation/user_select_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class UserSelectScreen extends ConsumerWidget {
  const UserSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSessionsAsync = ref.watch(savedSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
      ),
      body: SafeArea(
        child: savedSessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (sessions) => _buildSessionList(context, ref, sessions),
        ),
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    List<UserSession> sessions,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sessions.isNotEmpty) ...[
          Text(
            'Saved Profiles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...sessions.map((session) => _ProfileCard(session: session)),
          const SizedBox(height: 24),
        ],
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/server-connect');
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final UserSession session;

  const _ProfileCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(session.userName[0].toUpperCase()),
        ),
        title: Text(session.userName),
        subtitle: Text(session.serverUrl),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          try {
            await ref
                .read(authNotifierProvider.notifier)
                .switchToSession(session);
            // Navigation happens via auth state listener
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to restore session: $e')),
            );
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
flutter test test/widget/user_select_screen_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/user_select_screen.dart test/widget/user_select_screen_test.dart
git commit -m "feat: add UserSelectScreen for multi-user profile switching"
```

---

### Task 14: Placeholder Home Screen

**Files:**
- Create: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: Create home screen placeholder**

```dart
// lib/features/home/presentation/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState is Authenticated ? authState.session.userName : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AltEmby'),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            tooltip: 'Switch User',
            onPressed: () {
              Navigator.of(context).pushNamed('/user-select');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Welcome, $userName!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Connected successfully. Library browsing coming in Phase 2.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/home/
git commit -m "feat: add placeholder HomeScreen"
```

---

### Task 15: App Router with Auth Guards

**Files:**
- Create: `lib/app_router.dart`

- [ ] **Step 1: Implement GoRouter config**

```dart
// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/server-connect' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/user-select';

      if (!isAuthenticated && !isAuthRoute) {
        return '/server-connect';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/server-connect',
        builder: (context, state) => const ServerConnectScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/user-select',
        builder: (context, state) => const UserSelectScreen(),
      ),
    ],
  );
});
```

- [ ] **Step 2: Commit**

```bash
git add lib/app_router.dart
git commit -m "feat: add GoRouter with auth redirect guards"
```

---

### Task 16: App Theme

**Files:**
- Create: `lib/core/theme/app_theme.dart`

- [ ] **Step 1: Create dark and light themes**

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seedColor = Color(0xFF6366F1); // Indigo accent

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0A0A0A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1A1A),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/core/theme/
git commit -m "feat: add dark and light app themes"
```

---

### Task 17: Main Entry Point (Wiring Everything Together)

**Files:**
- Create/Modify: `lib/main.dart`

- [ ] **Step 1: Implement main.dart**

Replace the generated `lib/main.dart` with:

```dart
// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:altemby/app_router.dart';
import 'package:altemby/core/theme/app_theme.dart';
import 'package:altemby/core/utils/device_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  runApp(const ProviderScope(child: AltEmbyApp()));
}

class AltEmbyApp extends ConsumerStatefulWidget {
  const AltEmbyApp({super.key});

  @override
  ConsumerState<AltEmbyApp> createState() => _AltEmbyAppState();
}

class _AltEmbyAppState extends ConsumerState<AltEmbyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Initialize device ID on the interceptor
    final deviceUtils = ref.read(deviceUtilsProvider);
    final deviceId = await deviceUtils.getOrCreateDeviceId();
    ref.read(embyAuthInterceptorProvider).deviceId = deviceId;

    // Try to restore previous session
    await ref.read(authNotifierProvider.notifier).tryRestoreSession();

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AltEmby',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 2: Delete the generated test file**

Delete `test/widget_test.dart` (the default Flutter counter test) since it tests the now-replaced default app.

```bash
rm -f test/widget_test.dart
```

- [ ] **Step 3: Verify the app compiles**

```bash
flutter analyze
```

Expected: no analysis errors.

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart
git add -u test/
git commit -m "feat: wire up main.dart with Riverpod, GoRouter, and Hive init"
```

---

### Task 18: Update ServerConnectScreen Navigation for GoRouter

The ServerConnectScreen currently uses `Navigator.pushReplacementNamed` which won't work with GoRouter. Update to use GoRouter navigation.

**Files:**
- Modify: `lib/features/auth/presentation/server_connect_screen.dart`
- Modify: `lib/features/auth/presentation/user_select_screen.dart`
- Modify: `lib/features/home/presentation/home_screen.dart`

- [ ] **Step 1: Update ServerConnectScreen to use GoRouter**

In `server_connect_screen.dart`, add the import and replace the Navigator call:

Add at the top:
```dart
import 'package:go_router/go_router.dart';
```

Replace:
```dart
Navigator.of(context).pushReplacementNamed('/login');
```
With:
```dart
context.go('/login');
```

- [ ] **Step 2: Update UserSelectScreen to use GoRouter**

In `user_select_screen.dart`, add the import and replace:

Add at the top:
```dart
import 'package:go_router/go_router.dart';
```

Replace:
```dart
Navigator.of(context).pushReplacementNamed('/server-connect');
```
With:
```dart
context.go('/server-connect');
```

- [ ] **Step 3: Update HomeScreen to use GoRouter**

In `home_screen.dart`, add the import and replace:

Add at the top:
```dart
import 'package:go_router/go_router.dart';
```

Replace:
```dart
Navigator.of(context).pushNamed('/user-select');
```
With:
```dart
context.push('/user-select');
```

- [ ] **Step 4: Run all tests**

```bash
flutter test
```

Expected: all tests pass (widget tests use `MaterialApp` not the router, so they remain valid).

- [ ] **Step 5: Commit**

```bash
git add lib/features/
git commit -m "fix: use GoRouter navigation (context.go/push) instead of Navigator"
```

---

### Task 19: Final Integration Smoke Test

**Files:**
- None (verification only)

- [ ] **Step 1: Run the full test suite**

```bash
flutter test --reporter expanded
```

Expected: all tests pass, zero failures.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: no issues.

- [ ] **Step 3: Verify the app builds for Android**

```bash
flutter build apk --debug
```

Expected: BUILD SUCCESSFUL.

- [ ] **Step 4: Tag the milestone**

```bash
git tag -a v0.1.0-phase1 -m "Phase 1 complete: Foundation, API client, auth flow"
```

---

## Summary

Phase 1 delivers:
- **19 tasks**, each with TDD steps and explicit code
- A working Flutter app with dark theme
- Emby API client (Dio + auth interceptor)
- Server connect screen with URL validation and HTTPS warnings
- Login screen with username/password auth
- Multi-user profile picker (save/switch/remove sessions)
- Secure token storage (FlutterSecureStorage)
- GoRouter with auth guards (redirect unauthenticated users to login)
- Placeholder home screen ready for Phase 2 library browsing
- Comprehensive unit and widget tests
