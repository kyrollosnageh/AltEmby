// lib/shared/widgets/emby_image.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class EmbyImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const EmbyImage({super.key, required this.imageUrl, this.width, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[700]!,
        child: Container(width: width, height: height, color: Colors.grey[900]),
      ),
      errorWidget: (context, url, error) => Container(
        width: width, height: height, color: Colors.grey[900],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}
