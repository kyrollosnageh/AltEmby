import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:altemby/core/constants/app_constants.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/downloads/presentation/providers/download_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final serverInfo = ref.watch(serverInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Server section
          const _SectionHeader(title: 'Server'),
          if (serverInfo != null) ...[
            ListTile(
              leading: const Icon(Icons.dns),
              title: Text(serverInfo.serverName),
              subtitle: Text(serverInfo.url),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Server Version'),
              subtitle: Text(serverInfo.version),
            ),
          ],
          if (authState is Authenticated)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Current User'),
              subtitle: Text(authState.session.userName),
            ),
          ListTile(
            leading: const Icon(Icons.switch_account),
            title: const Text('Switch User'),
            onTap: () => context.push('/user-select'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz),
            title: const Text('Change Server'),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),

          // Playback section
          const _SectionHeader(title: 'Playback'),
          const _PlaybackQualitySetting(),
          const SwitchListTile(
            secondary: Icon(Icons.speed),
            title: Text('Hardware Decoding'),
            subtitle: Text('Use hardware acceleration when available'),
            value: true,
            onChanged: null, // Read-only for now, always enabled
          ),

          // Downloads section
          const _SectionHeader(title: 'Downloads'),
          _DownloadsStorageTile(),
          ListTile(
            leading: const Icon(Icons.delete_sweep),
            title: const Text('Clear All Downloads'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear Downloads?'),
                  content: const Text('This will delete all downloaded files.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                final service = ref.read(downloadServiceProvider);
                for (final dl in service.downloads) {
                  await service.removeDownload(dl.itemId);
                }
              }
            },
          ),

          // App section
          const _SectionHeader(title: 'App'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('Dark'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {}, // Theme switching deferred
          ),

          // About section
          const _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Open Source Licenses'),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: AppConstants.appVersion,
            ),
          ),

          // Logout
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _PlaybackQualitySetting extends StatelessWidget {
  const _PlaybackQualitySetting();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.high_quality),
      title: const Text('Remote Streaming Quality'),
      subtitle: const Text('Original (Direct Play)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Remote Streaming Quality',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                for (final q in [
                  'Original (Direct Play)',
                  '1080p - 20 Mbps',
                  '720p - 8 Mbps',
                  '480p - 2 Mbps',
                ])
                  ListTile(
                    title: Text(q),
                    trailing: q.startsWith('Original')
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DownloadsStorageTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(downloadServiceProvider);
    return FutureBuilder<int>(
      future: service.getTotalSize(),
      builder: (context, snapshot) {
        final sizeStr = snapshot.hasData
            ? '${(snapshot.data! / 1024 / 1024).toStringAsFixed(1)} MB'
            : 'Calculating...';
        return ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Storage Used'),
          subtitle: Text(sizeStr),
        );
      },
    );
  }
}
