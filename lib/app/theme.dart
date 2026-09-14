/// App-level ThemeData builder (Phase 9).
///
/// Tokens live in [AppRadii] / [AppMotion]; this file wires them into
/// MaterialApp so interactive surfaces share radius 8–12 and short motion.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:fluent_learning/core/theme_tokens.dart';

export 'package:fluent_learning/core/theme_tokens.dart';

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
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: const Color(0xFF121212),
    typography: Typography.material2021(
      platform: isIOS ? TargetPlatform.iOS : defaultTargetPlatform,
    ),
    fontFamily: fontFamily,
    textTheme: baseTextTheme
        .apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
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
          bodyLarge: TextStyle(fontWeight: bodyFontWeight),
          bodyMedium: TextStyle(fontWeight: bodyFontWeight),
          bodySmall: TextStyle(fontWeight: bodyFontWeight),
          titleLarge: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
          ),
          titleMedium: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
          ),
          titleSmall: TextStyle(
            fontWeight: titleFontWeight,
            fontFamily: resolvedDisplay,
          ),
          labelLarge: TextStyle(fontWeight: labelFontWeight),
          labelMedium: TextStyle(fontWeight: labelFontWeight),
          labelSmall: TextStyle(fontWeight: labelFontWeight),
        ),
    cupertinoOverrideTheme:
        isIOS ? const CupertinoThemeData(brightness: Brightness.dark) : null,
    colorScheme: const ColorScheme.dark(
      primary: Colors.blue,
      surface: Color(0xFF121212),
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: AppRadii.borderMd),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.borderMd,
        borderSide: const BorderSide(color: Colors.blueAccent),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}

/// Lightweight splash/bootstrap theme (no custom fonts required).
ThemeData buildAppBootstrapTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(primary: Color(0xFF6EA8FF)),
    useMaterial3: true,
  );
}
