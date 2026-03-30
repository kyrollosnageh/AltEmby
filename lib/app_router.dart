// lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/auth/presentation/server_connect_screen.dart';
import 'package:altemby/features/auth/presentation/login_screen.dart';
import 'package:altemby/features/auth/presentation/user_select_screen.dart';
import 'package:altemby/features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuthenticated = authState is Authenticated;
      final isAuthRoute = state.matchedLocation == '/server-connect' ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/user-select';

      if (!isAuthenticated && !isAuthRoute) {
        return '/server-connect';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/server-connect',
        builder: (context, state) => const ServerConnectScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/user-select',
        builder: (context, state) => const UserSelectScreen(),
      ),
    ],
  );
});
