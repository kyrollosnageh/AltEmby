import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

final continueWatchingProvider = FutureProvider.autoDispose<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getContinueWatching(userId: authState.session.userId);
});

final recentlyAddedProvider = FutureProvider.autoDispose<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getRecentlyAdded(userId: authState.session.userId);
});

final nextUpProvider = FutureProvider.autoDispose<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getNextUp(userId: authState.session.userId);
});
