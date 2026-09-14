import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/app/theme.dart';

void main() {
  group('AppRadii / AppMotion governance', () {
    test('radii stay in 8–12 band', () {
      expect(AppRadii.sm, inInclusiveRange(8, 12));
      expect(AppRadii.md, inInclusiveRange(8, 12));
      expect(AppRadii.lg, inInclusiveRange(8, 12));
    });

    test('motion durations stay snappy', () {
      expect(AppMotion.fast.inMilliseconds, inInclusiveRange(200, 280));
      expect(AppMotion.normal.inMilliseconds, inInclusiveRange(200, 280));
      expect(AppMotion.emphasized.inMilliseconds, inInclusiveRange(200, 280));
    });
  });

  group('AppBreakpoints + responsive helpers', () {
    test('breakpoint thresholds', () {
      expect(AppBreakpoints.compact, 600);
      expect(AppBreakpoints.medium, 1024);
      expect(AppBreakpoints.expanded, 1024);
    });

    testWidgets('context helpers map width bands', (tester) async {
      late AppBreakpoint bp;
      late bool compact;
      late bool medium;
      late bool expanded;

      Future<void> pumpAt(double width) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: Size(width, 800)),
            child: Builder(
              builder: (context) {
                bp = context.breakpoint;
                compact = context.isCompact;
                medium = context.isMedium;
                expanded = context.isExpanded;
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }

      await pumpAt(375);
      expect(bp, AppBreakpoint.compact);
      expect(compact, isTrue);
      expect(medium, isFalse);
      expect(expanded, isFalse);

      await pumpAt(800);
      expect(bp, AppBreakpoint.medium);
      expect(compact, isFalse);
      expect(medium, isTrue);
      expect(expanded, isFalse);

      await pumpAt(1280);
      expect(bp, AppBreakpoint.expanded);
      expect(compact, isFalse);
      expect(medium, isFalse);
      expect(expanded, isTrue);
    });
  });

  test('buildAppDarkTheme uses AppColors surfaces', () {
    final theme = buildAppDarkTheme(
      baseTextTheme: ThemeData.dark(useMaterial3: true).textTheme,
    );
    expect(theme.scaffoldBackgroundColor, AppColors.scaffold);
    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.surface, AppColors.surface);
    expect(theme.appBarTheme.backgroundColor, AppColors.elevated);
    expect(theme.cardTheme.color, AppColors.elevated);
  });

  test('pageTransitionsTheme uses fade+slide on Android/desktop, Cupertino on Apple', () {
    final theme = buildAppDarkTheme(
      baseTextTheme: ThemeData.dark(useMaterial3: true).textTheme,
    );
    final builders = theme.pageTransitionsTheme.builders;
    expect(
      builders[TargetPlatform.android],
      isA<AppFadeSlidePageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.windows],
      isA<AppFadeSlidePageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.linux],
      isA<AppFadeSlidePageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.iOS].runtimeType.toString(),
      'CupertinoPageTransitionsBuilder',
    );
    expect(
      builders[TargetPlatform.macOS].runtimeType.toString(),
      'CupertinoPageTransitionsBuilder',
    );
  });
}
