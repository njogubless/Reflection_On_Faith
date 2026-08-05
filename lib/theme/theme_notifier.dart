import 'package:devotion/core/util/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() => ThemeState();

  void toggleTheme(bool isDarkMode) {
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  void setPrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
  }
}

class ThemeState {
  final bool isDarkMode;
  final Color primaryColor;

  ThemeState({this.isDarkMode = false, this.primaryColor = AppTheme.brandSeed});

  // Delegates to the one real theme definition (AppTheme) instead of
  // building an ad hoc, mostly-empty ThemeData here — see app_theme.dart
  // for why that used to be a problem.
  ThemeData get theme =>
      isDarkMode ? AppTheme.dark(primaryColor) : AppTheme.light(primaryColor);

  ThemeState copyWith({
    bool? isDarkMode,
    Color? primaryColor,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(
  ThemeNotifier.new,
);
