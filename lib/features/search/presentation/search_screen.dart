import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/search/presentation/providers/search_providers.dart';
import 'package:altemby/shared/widgets/media_grid.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(hintText: 'Search movies, shows, music...', border: InputBorder.none, prefixIcon: Icon(Icons.search)),
          onChanged: _onSearchChanged,
          autofocus: true,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(icon: const Icon(Icons.clear), onPressed: () {
              _searchController.clear();
              ref.read(searchQueryProvider.notifier).state = '';
            }),
        ],
      ),
      body: query.isEmpty
          ? const Center(child: Text('Search your library', style: TextStyle(color: Colors.grey)))
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) => MediaGrid(items: items, baseUrl: baseUrl,
                onItemTap: (item) => context.push('/details/${item.id}')),
            ),
    );
  }
}
