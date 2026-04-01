import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:altemby/features/player/presentation/providers/player_providers.dart';
import 'package:altemby/features/player/presentation/widgets/player_controls.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  final String itemId;
  final String title;
  final int resumePositionTicks;

  const VideoPlayerScreen({
    super.key,
    required this.itemId,
    required this.title,
    this.resumePositionTicks = 0,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerNotifierProvider.notifier).openItem(
            itemId: widget.itemId,
            resumePositionTicks: widget.resumePositionTicks,
          );
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(playerNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: notifier.videoController,
            controls: NoVideoControls,
            fit: BoxFit.contain,
            fill: Colors.black,
          ),
          PlayerControls(title: widget.title),
        ],
      ),
    );
  }
}
