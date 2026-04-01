import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/shared/models/media_item.dart';

/// Fetches the server's library views (e.g. Movies, TV Shows, Music, etc.)
final userViewsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! Authenticated) return [];
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getUserViews(userId: authState.session.userId);
});

/// The currently selected library view (parentId). Null means "All".
final selectedViewProvider = StateProvider<MediaItem?>((ref) => null);

final librarySortByProvider = StateProvider<String>((ref) => 'SortName');
final librarySortOrderProvider = StateProvider<String>((ref) => 'Ascending');

class LibraryState {
  final List<MediaItem> items;
  final int totalCount;
  final bool isLoading;
  final String? error;

  const LibraryState({this.items = const [], this.totalCount = 0, this.isLoading = false, this.error});

  LibraryState copyWith({List<MediaItem>? items, int? totalCount, bool? isLoading, String? error}) {
    return LibraryState(items: items ?? this.items, totalCount: totalCount ?? this.totalCount,
      isLoading: isLoading ?? this.isLoading, error: error);
  }

  bool get hasMore => items.length < totalCount;
}

final libraryStateProvider = StateNotifierProvider.autoDispose<LibraryNotifier, LibraryState>((ref) => LibraryNotifier(ref));

class LibraryNotifier extends StateNotifier<LibraryState> {
  final Ref _ref;
  LibraryNotifier(this._ref) : super(const LibraryState());

  Future<void> loadInitial() async {
    final authState = _ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;
    state = state.copyWith(isLoading: true, items: [], error: null);
    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final selectedView = _ref.read(selectedViewProvider);
      final sortBy = _ref.read(librarySortByProvider);
      final sortOrder = _ref.read(librarySortOrderProvider);
      final result = await repo.getItems(
        userId: authState.session.userId,
        parentId: selectedView?.id,
        startIndex: 0, limit: 50, sortBy: sortBy, sortOrder: sortOrder,
      );
      state = LibraryState(items: result.items, totalCount: result.totalCount);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    final authState = _ref.read(authNotifierProvider);
    if (authState is! Authenticated) return;
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(libraryRepositoryProvider);
      final selectedView = _ref.read(selectedViewProvider);
      final sortBy = _ref.read(librarySortByProvider);
      final sortOrder = _ref.read(librarySortOrderProvider);
      final result = await repo.getItems(
        userId: authState.session.userId,
        parentId: selectedView?.id,
        startIndex: state.items.length, limit: 50, sortBy: sortBy, sortOrder: sortOrder,
      );
      state = LibraryState(items: [...state.items, ...result.items], totalCount: result.totalCount);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
