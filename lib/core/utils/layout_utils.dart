// lib/core/utils/layout_utils.dart

class LayoutUtils {
  LayoutUtils._();

  static int gridCrossAxisCount(double width) {
    if (width > 900) return 6;
    if (width > 600) return 4;
    return 3;
  }
}
