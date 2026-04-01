import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/app_shell.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/details/presentation/movie_detail_screen.dart';
import 'package:altemby/features/player/presentation/video_player_screen.dart';
import 'package:altemby/features/details/presentation/series_detail_screen.dart';
import 'package:altemby/features/details/presentation/providers/details_providers.dart';
import 'package:altemby/features/home/presentation/home_screen.dart';
import 'package:altemby/features/library/presentation/library_screen.dart';
import 'package:altemby/features/search/presentation/search_screen.dart';
import 'package:altemby/shared/models/media_item.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/server-connect' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/user-select';

      if (!isAuthenticated && !isAuthRoute) return '/server-connect';
      if (isAuthenticated && isAuthRoute) return '/';
      return null;
    },
    routes: [
      // Auth routes (no shell)
      GoRoute(path: '/server-connect', builder: (context, state) => const ServerConnectScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/user-select', parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UserSelectScreen()),

      // Main app with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(
            currentIndex: navigationShell.currentIndex,
            onTabSelected: (index) => navigationShell.goBranch(index),
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/library', builder: (context, state) => const LibraryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (context, state) => const Scaffold(
              body: Center(child: Text('Settings - Coming in Phase 7')))),
          ]),
        ],
      ),

      // Detail routes (full screen, above shell)
      GoRoute(path: '/details/:id', parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          return _DetailRouter(itemId: itemId);
        }),
      GoRoute(
        path: '/player/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final itemId = state.pathParameters['id']!;
          final title = state.uri.queryParameters['title'] ?? '';
          final resumeTicks =
              int.tryParse(state.uri.queryParameters['resume'] ?? '0') ?? 0;
          return VideoPlayerScreen(
            itemId: itemId,
            title: title,
            resumePositionTicks: resumeTicks,
          );
        },
      ),
    ],
  );
});

class _DetailRouter extends ConsumerWidget {
  final String itemId;
  const _DetailRouter({required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailProvider(itemId));
    return itemAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (item) {
        if (item.type == MediaType.series) return SeriesDetailScreen(itemId: itemId);
        return MovieDetailScreen(itemId: itemId);
      },
    );
  }
}
