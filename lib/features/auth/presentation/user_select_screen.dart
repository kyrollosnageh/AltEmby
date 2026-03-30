// lib/features/auth/presentation/user_select_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/features/auth/domain/user_session.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';

class UserSelectScreen extends ConsumerWidget {
  const UserSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedSessionsAsync = ref.watch(savedSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
      ),
      body: SafeArea(
        child: savedSessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (sessions) => _buildSessionList(context, ref, sessions),
        ),
      ),
    );
  }

  Widget _buildSessionList(
    BuildContext context,
    WidgetRef ref,
    List<UserSession> sessions,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sessions.isNotEmpty) ...[
          Text(
            'Saved Profiles',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ...sessions.map((session) => _ProfileCard(session: session)),
          const SizedBox(height: 24),
        ],
        OutlinedButton.icon(
          onPressed: () {
            context.go('/server-connect');
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Account'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends ConsumerWidget {
  final UserSession session;

  const _ProfileCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(session.userName[0].toUpperCase()),
        ),
        title: Text(session.userName),
        subtitle: Text(session.serverUrl),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          try {
            await ref
                .read(authNotifierProvider.notifier)
                .switchToSession(session);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to restore session: $e')),
            );
          }
        },
      ),
    );
  }
}
