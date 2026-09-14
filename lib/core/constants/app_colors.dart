import 'package:flutter/material.dart';

/// Bảng màu phong cách Obsidian / GitHub Dark tối ưu cho Flutter Desktop
class AppColors {
  // Nền chính
  static const Color background = Color(0xFF1E1E22);
  static const Color surface = Color(0xFF252529);
  static const Color surfaceVariant = Color(0xFF2E2E33);
  static const Color sidebarBackground = Color(0xFF18181A);

  // Đường viền & Phân cách
  static const Color border = Color(0xFF38383D);
  static const Color divider = Color(0xFF2E2E34);

  // Điểm nhấn (Accent Colors)
  static const Color primary = Color(0xFF7C4DFF); // Purple Accent
  static const Color primaryHover = Color(0xFF651FFF);
  static const Color secondary = Color(0xFF00B0FF); // Cyan
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF5252);

  // Màu chữ (Typography)
  static const Color textPrimary = Color(0xFFF0F0F2);
  static const Color textSecondary = Color(0xFF9E9EA7);
  static const Color textDisabled = Color(0xFF5E5E66);
  static const Color wikilink = Color(0xFF80D8FF); // Wikilink [[...]]
}
