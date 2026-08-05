import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:devotion/core/constants/sizes.dart';

/// The single source of truth for how the app looks, in both light and dark
/// mode.
///
/// Before this pass there were **four** separate, disconnected theme
/// definitions in the codebase (`theme/theme.dart`'s loose constants,
/// `theme/pallete.dart`'s `Pallete`, this file's old dead `appTheme()`
/// function with zero call sites, and the one that actually shipped —
/// `theme/theme_notifier.dart`'s inline `ThemeData`, which only set
/// `primaryColor`/`brightness`/`cardTheme`/`appBarTheme` and nothing else).
/// That last gap is why almost every screen resorted to hardcoding
/// `Colors.white` / `Colors.grey` / etc. directly instead of reading from a
/// theme that barely defined anything — which is also why dark mode never
/// looked right anywhere outside a handful of screens.
///
/// This consolidates all of that into one Material 3 `ColorScheme.fromSeed`
/// based theme (so light/dark and all the derived role colors — surfaces,
/// containers, on-colors with correct contrast — come from one seed color
/// instead of being hand-picked per screen), using the spacing/radius scale
/// already defined in `TSizes` and the Poppins font already bundled with the
/// app (see pubspec.yaml).
class AppTheme {
  AppTheme._();

  /// The app's brand color — this is the exact blue already used for the
  /// bottom nav's selected-tab color (the most visible branded element in
  /// the app), kept as-is rather than picked fresh, so this pass reads as a
  /// consistency fix, not a rebrand.
  static const Color brandSeed = Color(0xFF52A9F0);

  static ThemeData light([Color seed = brandSeed]) => _build(seed, Brightness.light);
  static ThemeData dark([Color seed = brandSeed]) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final isDark = brightness == Brightness.dark;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
    );

    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: TSizes.cardElevation,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: TSizes.dividerHeight,
      ),

      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          padding: const EdgeInsets.symmetric(vertical: TSizes.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: TSizes.md, vertical: TSizes.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.inputFieldRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusLg),
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.borderRadiusMd),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TSizes.cardRadiusMd),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: colorScheme.primary),

      drawerTheme: DrawerThemeData(backgroundColor: colorScheme.surface),
    );
  }
}
