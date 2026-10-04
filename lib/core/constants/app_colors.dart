import 'package:flutter/material.dart';

/// Bảng màu phong cách Obsidian / GitHub Dark tối ưu cho Flutter Desktop
/// [Member 4 - T4.1] Dark Theme Colors
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

  // [Member 4 - T4.1] Màu cho Resizable Splitter
  static const Color splitterIdle = Color(0xFF38383D);
  static const Color splitterHover = Color(0xFF7C4DFF);
  static const Color splitterDrag = Color(0xFF651FFF);

  // [Member 4 - T4.5] Màu cho Knowledge Graph
  static const Color graphNode = Color(0xFF7C4DFF);
  static const Color graphNodeActive = Color(0xFF00E676);
  static const Color graphEdge = Color(0xFF5E5E66);
  static const Color graphLabel = Color(0xFFF0F0F2);
}

/// [Member 4 - T4.1] Bảng màu Light Mode
/// Dùng cho tính năng chuyển đổi Dark/Light Theme
class LightColors {
  // Nền chính
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F4);
  static const Color sidebarBackground = Color(0xFFF5F5F8);

  // Đường viền & Phân cách
  static const Color border = Color(0xFFD8D8E0);
  static const Color divider = Color(0xFFE4E4EA);

  // Điểm nhấn (giữ giống Dark cho consistency)
  static const Color primary = Color(0xFF6200EA);
  static const Color primaryHover = Color(0xFF5600D4);
  static const Color secondary = Color(0xFF0091EA);
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFF8F00);
  static const Color error = Color(0xFFD50000);

  // Màu chữ
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6E6E80);
  static const Color textDisabled = Color(0xFFA0A0B0);
  static const Color wikilink = Color(0xFF0277BD);

  // Splitter
  static const Color splitterIdle = Color(0xFFD8D8E0);
  static const Color splitterHover = Color(0xFF6200EA);
  static const Color splitterDrag = Color(0xFF5600D4);

  // Knowledge Graph
  static const Color graphNode = Color(0xFF6200EA);
  static const Color graphNodeActive = Color(0xFF00C853);
  static const Color graphEdge = Color(0xFFA0A0B0);
  static const Color graphLabel = Color(0xFF1A1A2E);
}

/// Runtime palette for widgets that need to follow the active app theme.
class AppColorPalette {
  const AppColorPalette({
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.primary,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
  });

  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color primary;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  static const dark = AppColorPalette(
    surface: AppColors.surface,
    surfaceVariant: AppColors.surfaceVariant,
    border: AppColors.border,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
  );

  static const light = AppColorPalette(
    surface: LightColors.surface,
    surfaceVariant: LightColors.surfaceVariant,
    border: LightColors.border,
    primary: LightColors.primary,
    secondary: LightColors.secondary,
    success: LightColors.success,
    warning: LightColors.warning,
    error: LightColors.error,
    textPrimary: LightColors.textPrimary,
    textSecondary: LightColors.textSecondary,
    textDisabled: LightColors.textDisabled,
  );
}
