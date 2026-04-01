import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/home/presentation/providers/home_providers.dart';
import 'package:altemby/shared/models/media_item.dart';
import 'package:altemby/tv/widgets/tv_focus_card.dart';

class TvHomeScreen extends ConsumerWidget {
  const TvHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(continueWatchingProvider);
    final recentlyAdded = ref.watch(recentlyAddedProvider);
    final nextUp = ref.watch(nextUpProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 48, left: 48),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Text('AltEmby', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ..._buildSection(context, 'Continue Watching', continueWatching, baseUrl, autofocusFirst: true),
            ..._buildSection(context, 'Next Up', nextUp, baseUrl),
            ..._buildSection(context, 'Recently Added', recentlyAdded, baseUrl),
            const SliverToBoxAdapter(child: SizedBox(height: 48)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSection(BuildContext context, String title,
      AsyncValue<List<MediaItem>> asyncValue, String baseUrl,
      {bool autofocusFirst = false}) {
    return asyncValue.when(
      loading: () => [const SliverToBoxAdapter(child: SizedBox.shrink())],
      error: (_, __) => [const SliverToBoxAdapter(child: SizedBox.shrink())],
      data: (items) {
        if (items.isEmpty) return [const SliverToBoxAdapter(child: SizedBox.shrink())];
        return [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 24),
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 320,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) => TvFocusCard(
                  item: items[index],
                  baseUrl: baseUrl,
                  autofocus: autofocusFirst && index == 0,
                  onSelect: () => context.push('/details/${items[index].id}'),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
