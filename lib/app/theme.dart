/// App-level ThemeData builder (Phase 9 / beautify U1–U4).
///
/// Tokens live in [AppColors] / [AppRadii] / [AppMotion]; this file wires them
/// into MaterialApp so interactive surfaces share radius 8–12 and short motion.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

export 'package:fluent_learning/core/theme_tokens.dart';

ColorScheme _appDarkColorScheme() {
  return const ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primary,
    onSecondary: AppColors.onPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    surfaceContainerLowest: AppColors.scaffold,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surfaceContainer,
    surfaceContainerHigh: AppColors.elevated,
    surfaceContainerHighest: AppColors.elevated,
    error: AppColors.error,
    onError: AppColors.onError,
    outline: AppColors.outline,
    outlineVariant: AppColors.outlineVariant,
  );
}


/// Short fade + slight horizontal slide for Android / desktop routes.
///
/// Curves and perceived timing follow [AppMotion]; iOS/macOS keep Cupertino.
class AppFadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const AppFadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final primary = CurvedAnimation(
      parent: animation,
      curve: AppMotion.standard,
      reverseCurve: AppMotion.accelerate,
    );
    // Secondary route eases out slightly so the incoming page reads as a short cross-fade.
    final secondary = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.decelerate,
      reverseCurve: AppMotion.standard,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(primary),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(primary),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.92).animate(secondary),
          child: child,
        ),
      ),
    );
  }
}

/// Builds the shared dark [ThemeData] used by MaterialApp.
ThemeData buildAppDarkTheme({
  required TextTheme baseTextTheme,
  String? fontFamily,
  String? displayFontFamily,
  FontWeight bodyFontWeight = FontWeight.w400,
  FontWeight titleFontWeight = FontWeight.w600,
  FontWeight labelFontWeight = FontWeight.w500,
  bool isIOS = false,
}) {
  final resolvedDisplay = displayFontFamily ?? fontFamily;
  final colorScheme = _appDarkColorScheme();
  final onSurface = AppColors.onSurface;

  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: colorScheme,
    typography: Typography.material2021(
      platform: isIOS ? TargetPlatform.iOS : defaultTargetPlatform,
    ),
    fontFamily: fontFamily,
    textTheme: baseTextTheme
        .apply(
          bodyColor: onSurface,
          displayColor: onSurface,
          fontFamily: fontFamily,
        )
        .copyWith(
          displayLarge:
              baseTextTheme.displayLarge?.copyWith(fontFamily: resolvedDisplay),
          displayMedium: baseTextTheme.displayMedium
              ?.copyWith(fontFamily: resolvedDisplay),
          displaySmall:
              baseTextTheme.displaySmall?.copyWith(fontFamily: resolvedDisplay),
          headlineLarge: baseTextTheme.headlineLarge
              ?.copyWith(fontFamily: resolvedDisplay),
          headlineMedium: baseTextTheme.headlineMedium
              ?.copyWith(fontFamily: resolvedDisplay),
          headlineSmall: baseTextTheme.headlineSmall
              ?.copyWith(fontFamily: resolvedDisplay),
          bodyLarge: TextStyle(fontWeight: bodyFontWeight, color: onSurface),
          bodyMedium: TextStyle(fontWeight: bodyFontWeight, color: onSurface),
          bodySmall: TextStyle(
            fontWeight: bodyFontWeight,
            color: AppColors.onSurfaceVariant,
          ),
          titleLarge: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
            color: onSurface,
          ),
          titleMedium: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
            color: onSurface,
          ),
          titleSmall: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
            color: onSurface,
          ),
          labelLarge: TextStyle(fontWeight: labelFontWeight, color: onSurface),
          labelMedium: TextStyle(fontWeight: labelFontWeight, color: onSurface),
          labelSmall: TextStyle(
            fontWeight: labelFontWeight,
            color: AppColors.onSurfaceVariant,
          ),
        ),
    cupertinoOverrideTheme:
        isIOS ? const CupertinoThemeData(brightness: Brightness.dark) : null,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.elevated,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.elevated,
      indicatorColor: AppColors.primary.withValues(alpha: 0.24),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppColors.elevated,
      indicatorColor: AppColors.primary.withValues(alpha: 0.24),
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme:
          const IconThemeData(color: AppColors.onSurfaceVariant),
      selectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.elevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceContainer,
      contentTextStyle: const TextStyle(color: AppColors.onSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.elevated,
        foregroundColor: AppColors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceContainer,
      border: OutlineInputBorder(borderRadius: AppRadii.borderMd),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.onSurfaceVariant),
      labelStyle: const TextStyle(color: AppColors.onSurfaceVariant),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppFadeSlidePageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: AppFadeSlidePageTransitionsBuilder(),
        TargetPlatform.linux: AppFadeSlidePageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppFadeSlidePageTransitionsBuilder(),
      },
    ),
  );
}

/// Lightweight splash/bootstrap theme (no custom fonts required).
ThemeData buildAppBootstrapTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.scaffold,
    colorScheme: _appDarkColorScheme(),
    useMaterial3: true,
  );
}
