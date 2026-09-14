import 'package:flutter/material.dart';
import 'package:fluent_learning/app/responsive.dart';
import 'package:fluent_learning/core/theme_tokens.dart';
import 'package:fluent_learning/features/calendar/calendar_tab_page.dart';
import 'package:fluent_learning/features/centers/centers_tab_page.dart';
import 'package:fluent_learning/features/home/home_tab_page.dart';
import 'package:fluent_learning/features/library/library_selection_active.dart';
import 'package:fluent_learning/features/library/library_tab_page.dart';
import 'package:fluent_learning/features/mine/mine_tab_page.dart';

/// Request [MainShell] to switch tabs (e.g. Home empty CTA → Library).
///
/// Set to a tab index; [MainShell] applies and clears back to null.
final ValueNotifier<int?> mainShellTabRequest = ValueNotifier<int?>(null);

/// Tab indices for [MainShell] / [mainShellTabRequest].
abstract final class MainShellTab {
  static const int home = 0;
  static const int library = 1;
  static const int calendar = 2;
  static const int centers = 3;
  static const int mine = 4;
}

/// Root 5-tab shell for Phase 1.
///
/// Uses [IndexedStack] so each tab keeps its state (including the embedded
/// media-library [HomeScreen] under 「媒体库」).
///
/// Beautify U2: compact keeps bottom [NavigationBar]; medium+ uses
/// [NavigationRail]. Selection semantics are unchanged.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  /// Tab order: 首页 / 媒体库 / 日历 / 中心 / 我的
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  /// Library tab index in [_tabs] / IndexedStack.
  static const int _libraryTabIndex = MainShellTab.library;

  static const List<_ShellTab> _tabs = <_ShellTab>[
    _ShellTab(
      label: '首页',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    _ShellTab(
      label: '媒体库',
      icon: Icons.video_library_outlined,
      selectedIcon: Icons.video_library,
    ),
    _ShellTab(
      label: '日历',
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today,
    ),
    _ShellTab(
      label: '中心',
      icon: Icons.hub_outlined,
      selectedIcon: Icons.hub,
    ),
    _ShellTab(
      label: '我的',
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, _tabs.length - 1);
    mainShellTabRequest.addListener(_onTabRequest);
  }

  @override
  void dispose() {
    mainShellTabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  void _onTabRequest() {
    final requested = mainShellTabRequest.value;
    if (requested == null) return;
    // Clear so the same tab can be requested again later.
    mainShellTabRequest.value = null;
    final index = requested.clamp(0, _tabs.length - 1);
    if (index == _currentIndex || !mounted) return;
    setState(() => _currentIndex = index);
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  Widget _buildTabStack() {
    return IndexedStack(
      index: _currentIndex,
      children: const <Widget>[
        HomeTabPage(),
        LibraryTabPage(),
        CalendarTabPage(),
        CentersTabPage(),
        MineTabPage(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      backgroundColor: AppColors.elevated,
      indicatorColor: AppColors.primary.withValues(alpha: 0.24),
      destinations: [
        for (final tab in _tabs)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: tab.label,
          ),
      ],
    );
  }

  Widget _buildRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabSelected,
      backgroundColor: AppColors.elevated,
      indicatorColor: AppColors.primary.withValues(alpha: 0.24),
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme:
          const IconThemeData(color: AppColors.onSurfaceVariant),
      selectedLabelTextStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: const TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      destinations: [
        for (final tab in _tabs)
          NavigationRailDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: Text(tab.label),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;

    return ValueListenableBuilder<bool>(
      valueListenable: librarySelectionActive,
      builder: (context, selectionActive, _) {
        // Phase 8: hide shell nav while Library multi-select shows its own
        // BottomAppBar — avoids stacking two bottom bars / chrome.
        final hideForLibrarySelect =
            _currentIndex == _libraryTabIndex && selectionActive;

        final stack = _buildTabStack();

        final Widget body;
        if (compact) {
          body = stack;
        } else {
          body = Row(
            children: [
              AnimatedSwitcher(
                duration: AppMotion.normal,
                switchInCurve: AppMotion.standard,
                switchOutCurve: AppMotion.accelerate,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      alignment: Alignment.centerLeft,
                      child: child,
                    ),
                  );
                },
                child: hideForLibrarySelect
                    ? const SizedBox.shrink(key: ValueKey('rail-hidden'))
                    : KeyedSubtree(
                        key: const ValueKey('rail-visible'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildRail(context),
                            const VerticalDivider(
                              width: 1,
                              thickness: 1,
                              color: AppColors.outlineVariant,
                            ),
                          ],
                        ),
                      ),
              ),
              Expanded(child: stack),
            ],
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffold,
          body: body,
          bottomNavigationBar: compact
              ? AnimatedSwitcher(
                  duration: AppMotion.normal,
                  switchInCurve: AppMotion.standard,
                  switchOutCurve: AppMotion.accelerate,
                  child: hideForLibrarySelect
                      ? const SizedBox.shrink(key: ValueKey('bar-hidden'))
                      : KeyedSubtree(
                          key: const ValueKey('bar-visible'),
                          child: _buildBottomBar(),
                        ),
                )
              : null,
        );
      },
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
