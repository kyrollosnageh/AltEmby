import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/home/presentation/providers/home_providers.dart';
import 'package:altemby/features/home/presentation/widgets/home_section.dart';
import 'package:altemby/shared/models/media_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final nextUp = ref.watch(nextUpProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(continueWatchingProvider);
          ref.invalidate(recentlyAddedProvider);
          ref.invalidate(nextUpProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('AltEmby'),
              actions: [
                IconButton(icon: const Icon(Icons.switch_account), tooltip: 'Switch User',
                  onPressed: () => context.push('/user-select')),
                IconButton(icon: const Icon(Icons.logout), tooltip: 'Sign Out',
                  onPressed: () async => await ref.read(authNotifierProvider.notifier).logout()),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSection(context, title: 'Continue Watching', asyncValue: continueWatching, baseUrl: baseUrl),
                  _buildSection(context, title: 'Next Up', asyncValue: nextUp, baseUrl: baseUrl),
                  _buildSection(context, title: 'Recently Added', asyncValue: recentlyAdded, baseUrl: baseUrl),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required AsyncValue<List<MediaItem>> asyncValue, required String baseUrl}) {
    return asyncValue.when(
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
        ]),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) => HomeSection(
        title: title, items: items, baseUrl: baseUrl,
        onItemTap: (item) => context.push('/details/${item.id}'),
      ),
    );
  }
}
