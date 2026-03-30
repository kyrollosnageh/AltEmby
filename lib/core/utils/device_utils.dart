// lib/core/utils/device_utils.dart

import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceUtils {
  final FlutterSecureStorage _secureStorage;

  DeviceUtils({required FlutterSecureStorage secureStorage})
      : _secureStorage = secureStorage;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _secureStorage.read(key: 'device_id');
    if (existing != null) return existing;

    final newId = const Uuid().v4();
    await _secureStorage.write(key: 'device_id', value: newId);
    return newId;
  }

  static String getDeviceName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'Flutter Device';
    }
  }

  /// Checks for Android TV via system features.
  /// Must be called from Android only. Returns false on other platforms.
  static Future<bool> isAndroidTv() async {
    if (!Platform.isAndroid) return false;
    // Actual check requires device_info_plus; deferred to app startup.
    // This is a placeholder that will be wired up in main.dart.
    return false;
  }
}
