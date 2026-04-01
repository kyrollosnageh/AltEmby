import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/library/presentation/providers/library_providers.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/shared/widgets/media_grid.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});
  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _initialLoadDone = false;

  @override
  Widget build(BuildContext context) {
    final viewsAsync = ref.watch(userViewsProvider);
    final selectedView = ref.watch(selectedViewProvider);
    final libraryState = ref.watch(libraryStateProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    // Auto-select first view and load when views arrive
    ref.listen(userViewsProvider, (prev, next) {
      next.whenData((views) {
        if (!_initialLoadDone && views.isNotEmpty) {
          _initialLoadDone = true;
          final current = ref.read(selectedViewProvider);
          if (current == null) {
            ref.read(selectedViewProvider.notifier).state = views.first;
            ref.read(libraryStateProvider.notifier).loadInitial();
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: viewsAsync.when(
            loading: () => const SizedBox(height: 48, child: Center(child: LinearProgressIndicator())),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Failed to load libraries', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
            data: (views) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: views.map((view) {
                  final isSelected = selectedView?.id == view.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(view.name),
                      selected: isSelected,
                      onSelected: (_) {
                        ref.read(selectedViewProvider.notifier).state = view;
                        ref.read(libraryStateProvider.notifier).loadInitial();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
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
