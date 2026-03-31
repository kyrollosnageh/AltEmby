// lib/shared/widgets/shimmer_grid.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double childAspectRatio;
  const ShimmerGrid({super.key, this.itemCount = 12, this.childAspectRatio = 0.55});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[900]!,
      highlightColor: Colors.grey[700]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _crossAxisCount(context), childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 6;
    if (width > 600) return 4;
    return 3;
  }
}
