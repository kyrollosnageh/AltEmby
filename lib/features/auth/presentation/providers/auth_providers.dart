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
