// lib/shared/widgets/shimmer_grid.dart

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:altemby/core/utils/layout_utils.dart';

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
          crossAxisCount: LayoutUtils.gridCrossAxisCount(MediaQuery.of(context).size.width), childAspectRatio: childAspectRatio,
          crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: itemCount,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8))),
      ),
    );
  }

}
