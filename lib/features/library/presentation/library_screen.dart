import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/library/presentation/providers/library_providers.dart';
import 'package:altemby/shared/widgets/media_grid.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryStateProvider.notifier).loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryStateProvider);
    final currentType = ref.watch(libraryTypeProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              _TypeChip(label: 'Movies', type: 'Movie', current: currentType),
              const SizedBox(width: 8),
              _TypeChip(label: 'Shows', type: 'Series', current: currentType),
              const SizedBox(width: 8),
              _TypeChip(label: 'Music', type: 'MusicAlbum', current: currentType),
              const SizedBox(width: 8),
              _TypeChip(label: 'Collections', type: 'BoxSet', current: currentType),
            ]),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort), tooltip: 'Sort',
            onSelected: (value) {
              final parts = value.split(':');
              ref.read(librarySortByProvider.notifier).state = parts[0];
              ref.read(librarySortOrderProvider.notifier).state = parts[1];
              ref.read(libraryStateProvider.notifier).loadInitial();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'SortName:Ascending', child: Text('Name (A-Z)')),
              const PopupMenuItem(value: 'SortName:Descending', child: Text('Name (Z-A)')),
              const PopupMenuItem(value: 'DateCreated:Descending', child: Text('Date Added')),
              const PopupMenuItem(value: 'CommunityRating:Descending', child: Text('Rating')),
              const PopupMenuItem(value: 'ProductionYear:Descending', child: Text('Year')),
              const PopupMenuItem(value: 'Random:Ascending', child: Text('Random')),
            ],
          ),
        ],
      ),
      body: libraryState.error != null
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Error: ${libraryState.error}'), const SizedBox(height: 16),
              FilledButton(onPressed: () => ref.read(libraryStateProvider.notifier).loadInitial(), child: const Text('Retry'))]))
          : MediaGrid(items: libraryState.items, baseUrl: baseUrl, isLoading: libraryState.isLoading,
              hasMore: libraryState.hasMore, onLoadMore: () => ref.read(libraryStateProvider.notifier).loadMore(),
              onItemTap: (item) => context.push('/details/${item.id}')),
    );
  }
}

class _TypeChip extends ConsumerWidget {
  final String label;
  final String type;
  final String current;
  const _TypeChip({required this.label, required this.type, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = type == current;
    return FilterChip(label: Text(label), selected: isSelected, onSelected: (_) {
      ref.read(libraryTypeProvider.notifier).state = type;
      ref.read(libraryStateProvider.notifier).loadInitial();
    });
  }
}
