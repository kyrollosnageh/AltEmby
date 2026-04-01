import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/search/data/search_repository.dart';
import 'package:altemby/shared/models/media_item.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(apiClient: ref.watch(embyApiClientProvider)),
);

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(searchRepositoryProvider);
  final result = await repo.search(userId: authState.session.userId, query: query);
  return result.items;
});
