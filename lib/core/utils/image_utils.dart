// lib/core/utils/image_utils.dart

import 'package:altemby/core/api/api_endpoints.dart';

class ImageUtils {
  ImageUtils._();

  static String itemImageUrl({
    required String baseUrl,
    required String itemId,
    String imageType = 'Primary',
    String? tag,
    int? maxWidth,
    int? maxHeight,
    int? index,
  }) {
    final path = ApiEndpoints.itemImage(itemId, imageType, index: index);
    final params = <String, String>{
      if (tag != null) 'tag': tag,
      if (maxWidth != null) 'maxWidth': maxWidth.toString(),
      if (maxHeight != null) 'maxHeight': maxHeight.toString(),
      'quality': '90',
    };
    if (params.isEmpty) return '$baseUrl$path';
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$baseUrl$path?$query';
  }

  static String thumbnailUrl({
    required String baseUrl, required String itemId, String? tag,
  }) => itemImageUrl(baseUrl: baseUrl, itemId: itemId, tag: tag, maxWidth: 300);

  static String posterUrl({
    required String baseUrl, required String itemId, String? tag,
  }) => itemImageUrl(baseUrl: baseUrl, itemId: itemId, tag: tag, maxWidth: 500);

  static String backdropUrl({
    required String baseUrl, required String itemId, String? tag, int index = 0,
  }) => itemImageUrl(baseUrl: baseUrl, itemId: itemId, imageType: 'Backdrop', tag: tag, maxWidth: 1280, index: index);
}
