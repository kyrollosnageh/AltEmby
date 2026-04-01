// lib/features/player/presentation/providers/audio_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/player/data/audio_player_service.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final reporter = ref.watch(playbackReporterProvider);
  final apiClient = ref.watch(embyApiClientProvider);
  final service = AudioPlayerService(
    reporter: reporter,
    baseUrl: apiClient.baseUrl,
    token: apiClient.authInterceptor.token,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final audioPlayerStateProvider = StreamProvider<AudioPlayerState>((ref) {
  final service = ref.watch(audioPlayerServiceProvider);
  return service.stateStream;
});
