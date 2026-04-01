import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:altemby/core/api/api_endpoints.dart';
import 'package:altemby/core/api/emby_api_client.dart';
import 'package:altemby/shared/models/media_item.dart';

enum DownloadStatus { queued, downloading, completed, failed }

class DownloadItem {
  final String itemId;
  final String name;
  final String type;
  final String? imageTag;
  final DownloadStatus status;
  final double progress;
  final String? filePath;
  final int fileSize;
  final DateTime addedAt;

  const DownloadItem({
    required this.itemId,
    required this.name,
    required this.type,
    this.imageTag,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.filePath,
    this.fileSize = 0,
    required this.addedAt,
  });

  DownloadItem copyWith({
    DownloadStatus? status,
    double? progress,
    String? filePath,
    int? fileSize,
  }) => DownloadItem(
    itemId: itemId, name: name, type: type, imageTag: imageTag,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    addedAt: addedAt,
  );

  Map<String, dynamic> toJson() => {
    'itemId': itemId, 'name': name, 'type': type, 'imageTag': imageTag,
    'status': status.index, 'progress': progress, 'filePath': filePath,
    'fileSize': fileSize, 'addedAt': addedAt.toIso8601String(),
  };

  factory DownloadItem.fromJson(Map<String, dynamic> json) => DownloadItem(
    itemId: json['itemId'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    imageTag: json['imageTag'] as String?,
    status: DownloadStatus.values[json['status'] as int],
    progress: (json['progress'] as num).toDouble(),
    filePath: json['filePath'] as String?,
    fileSize: json['fileSize'] as int? ?? 0,
    addedAt: DateTime.parse(json['addedAt'] as String),
  );
}

class DownloadService {
  final EmbyApiClient _apiClient;
  final Dio _dio;
  final _stateController = StreamController<List<DownloadItem>>.broadcast();
  Stream<List<DownloadItem>> get stateStream => _stateController.stream;

  final Map<String, DownloadItem> _downloads = {};
  final Map<String, CancelToken> _cancelTokens = {};

  List<DownloadItem> get downloads => _downloads.values.toList()
    ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  DownloadService({required EmbyApiClient apiClient})
      : _apiClient = apiClient,
        _dio = Dio() {
    // Emit initial empty state
    _stateController.add(downloads);
  }

  /// Get or create an encryption key for the downloads Hive box.
  Future<List<int>> _getEncryptionKey() async {
    const storage = FlutterSecureStorage();
    const keyName = 'downloads_hive_key';
    final existing = await storage.read(key: keyName);
    if (existing != null) {
      return base64Decode(existing);
    }
    final random = Random.secure();
    final key = List<int>.generate(32, (_) => random.nextInt(256));
    await storage.write(key: keyName, value: base64Encode(key));
    return key;
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen('downloads_enc')) {
      return Hive.box('downloads_enc');
    }
    final key = await _getEncryptionKey();
    return Hive.openBox('downloads_enc',
        encryptionCipher: HiveAesCipher(key));
  }

  Future<void> loadFromStorage() async {
    final box = await _openBox();
    for (final key in box.keys) {
      final json = box.get(key);
      if (json != null) {
        var item = DownloadItem.fromJson(Map<String, dynamic>.from(json as Map));
        // Recover from app killed mid-download
        if (item.status == DownloadStatus.downloading) {
          item = item.copyWith(status: DownloadStatus.failed);
          await box.put(item.itemId, item.toJson());
        }
        _downloads[item.itemId] = item;
      }
    }
    _notify();
  }

  Future<void> _save(DownloadItem item) async {
    final box = await _openBox();
    await box.put(item.itemId, item.toJson());
  }

  Future<void> _remove(String itemId) async {
    final box = await _openBox();
    await box.delete(itemId);
  }

  void _notify() => _stateController.add(downloads);

  Future<void> addDownload(MediaItem item) async {
    if (_downloads.containsKey(item.id)) return;

    final dlItem = DownloadItem(
      itemId: item.id,
      name: item.name,
      type: item.type.name,
      imageTag: item.primaryImageTag,
      addedAt: DateTime.now(),
    );
    _downloads[item.id] = dlItem;
    await _save(dlItem);
    _notify();
    _startDownload(dlItem);
  }

  Future<void> _startDownload(DownloadItem item) async {
    final dir = await _getDownloadDir();
    // Use random filename to prevent enumeration of downloaded content
    final random = Random.secure();
    final randomHex = List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    final filePath = '${dir.path}/$randomHex.media';

    final cancelToken = CancelToken();
    _cancelTokens[item.itemId] = cancelToken;

    _updateItem(item.itemId, status: DownloadStatus.downloading);

    try {
      final path = ApiEndpoints.fileDownload(item.itemId);
      final url = _apiClient.getStreamUrl(path);

      await _dio.download(
        url,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _updateItem(item.itemId,
                progress: received / total, fileSize: total);
          }
        },
      );

      _updateItem(item.itemId,
          status: DownloadStatus.completed, filePath: filePath, progress: 1.0);
    } on DioException catch (e) {
      if (e.type != DioExceptionType.cancel) {
        _updateItem(item.itemId, status: DownloadStatus.failed);
        // Clean up partial file
        final partialFile = File(filePath);
        if (await partialFile.exists()) await partialFile.delete();
      }
    } catch (_) {
      _updateItem(item.itemId, status: DownloadStatus.failed);
      // Clean up partial file
      final partialFile = File(filePath);
      if (await partialFile.exists()) await partialFile.delete();
    } finally {
      _cancelTokens.remove(item.itemId);
    }
  }

  void _updateItem(String itemId,
      {DownloadStatus? status, double? progress, String? filePath, int? fileSize}) {
    final existing = _downloads[itemId];
    if (existing == null) return;
    final updated = existing.copyWith(
        status: status, progress: progress, filePath: filePath, fileSize: fileSize);
    _downloads[itemId] = updated;
    _save(updated);
    _notify();
  }

  Future<void> cancelDownload(String itemId) async {
    _cancelTokens[itemId]?.cancel();
    _cancelTokens.remove(itemId);
    await removeDownload(itemId);
  }

  Future<void> removeDownload(String itemId) async {
    final item = _downloads[itemId];
    if (item?.filePath != null) {
      final file = File(item!.filePath!);
      if (await file.exists()) await file.delete();
    }
    _downloads.remove(itemId);
    await _remove(itemId);
    _notify();
  }

  Future<void> retryDownload(String itemId) async {
    final item = _downloads[itemId];
    if (item == null) return;
    _startDownload(item);
  }

  bool isDownloaded(String itemId) =>
      _downloads[itemId]?.status == DownloadStatus.completed;

  String? getLocalPath(String itemId) => _downloads[itemId]?.filePath;

  Future<int> getTotalSize() async {
    int total = 0;
    for (final item in _downloads.values) {
      total += item.fileSize;
    }
    return total;
  }

  Future<Directory> _getDownloadDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dlDir = Directory('${appDir.path}/downloads');
    if (!await dlDir.exists()) await dlDir.create(recursive: true);
    return dlDir;
  }

  void dispose() {
    for (final token in _cancelTokens.values) {
      token.cancel();
    }
    _stateController.close();
  }
}
