import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:altemby/core/utils/image_utils.dart';
import 'package:altemby/features/auth/presentation/providers/auth_providers.dart';
import 'package:altemby/features/downloads/data/download_service.dart';
import 'package:altemby/features/downloads/presentation/providers/download_providers.dart';
import 'package:altemby/shared/widgets/emby_image.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadsAsync = ref.watch(downloadsProvider);
    final baseUrl = ref.watch(embyApiClientProvider).baseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: downloadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (downloads) {
          if (downloads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No downloads yet', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Download movies and shows to watch offline',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, index) {
              final item = downloads[index];
              return _DownloadTile(item: item, baseUrl: baseUrl);
            },
          );
        },
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadItem item;
  final String baseUrl;

  const _DownloadTile({required this.item, required this.baseUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(downloadServiceProvider);

    return ListTile(
      leading: SizedBox(
        width: 56, height: 84,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: EmbyImage(
            imageUrl: ImageUtils.thumbnailUrl(
              baseUrl: baseUrl, itemId: item.itemId, tag: item.imageTag),
          ),
        ),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(service),
    );
  }

  Widget _buildSubtitle() {
    return switch (item.status) {
      DownloadStatus.queued => const Text('Queued', style: TextStyle(color: Colors.grey)),
      DownloadStatus.downloading => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: item.progress),
            const SizedBox(height: 4),
            Text('${(item.progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      DownloadStatus.completed => Text(
          '${(item.fileSize / 1024 / 1024).toStringAsFixed(0)} MB',
          style: const TextStyle(color: Colors.grey)),
      DownloadStatus.failed => const Text('Failed', style: TextStyle(color: Colors.red)),
    };
  }

  Widget? _buildTrailing(DownloadService service) {
    return switch (item.status) {
      DownloadStatus.downloading => IconButton(
          icon: const Icon(Icons.close), onPressed: () => service.cancelDownload(item.itemId)),
      DownloadStatus.completed => IconButton(
          icon: const Icon(Icons.delete_outline), onPressed: () => service.removeDownload(item.itemId)),
      DownloadStatus.failed => IconButton(
          icon: const Icon(Icons.refresh), onPressed: () => service.retryDownload(item.itemId)),
      _ => null,
    };
  }
}
