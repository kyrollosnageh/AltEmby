import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/downloads/data/download_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  final apiClient = ref.watch(embyApiClientProvider);
  final service = DownloadService(apiClient: apiClient);
  ref.onDispose(() => service.dispose());
  return service;
});

final downloadsProvider = StreamProvider<List<DownloadItem>>((ref) {
  final service = ref.watch(downloadServiceProvider);
  return service.stateStream;
});
