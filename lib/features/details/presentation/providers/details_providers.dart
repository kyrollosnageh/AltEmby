import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

final itemDetailProvider = FutureProvider.family<MediaItem, String>((ref, itemId) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getItemDetails(itemId: itemId, userId: authState.session.userId);
});

final similarItemsProvider = FutureProvider.family<List<MediaItem>, String>((ref, itemId) async {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getSimilarItems(itemId: itemId);
});

final seasonsProvider = FutureProvider.family<List<MediaItem>, String>((ref, seriesId) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getSeasons(seriesId: seriesId, userId: authState.session.userId);
});

final episodesProvider = FutureProvider.family<List<MediaItem>, ({String seriesId, String seasonId})>((ref, params) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) throw Exception('Not authenticated');
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getEpisodes(seriesId: params.seriesId, seasonId: params.seasonId, userId: authState.session.userId);
});
