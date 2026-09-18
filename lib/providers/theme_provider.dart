import 'package:flutter/material.dart';

/// [Member 4 - T4.3] Quản lý trạng thái Dark/Light Theme cho toàn ứng dụng.
///
/// Sử dụng trong `MaterialApp` qua `Consumer<ThemeProvider>` để chuyển đổi
/// theme động mà không cần restart ứng dụng.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  /// Theme hiện tại (mặc định: Dark)
  ThemeMode get themeMode => _themeMode;

  /// `true` nếu đang ở chế độ Dark Mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Chuyển đổi qua lại giữa Dark và Light mode
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Đặt theme cụ thể (dùng khi cần force set từ Settings)
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }
}
