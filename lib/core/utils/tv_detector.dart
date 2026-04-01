import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isTvProvider = FutureProvider<bool>((ref) async {
  if (!Platform.isAndroid) return false;
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.systemFeatures.contains('android.software.leanback') ||
      androidInfo.systemFeatures.contains('android.hardware.type.television');
});
