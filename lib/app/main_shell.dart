import 'package:flutter/material.dart';
import 'package:fluent_learning/features/calendar/calendar_tab_page.dart';
import 'package:fluent_learning/features/centers/centers_tab_page.dart';
import 'package:fluent_learning/features/home/home_tab_page.dart';
import 'package:fluent_learning/features/library/library_selection_active.dart';
import 'package:fluent_learning/features/library/library_tab_page.dart';
import 'package:fluent_learning/features/mine/mine_tab_page.dart';

/// Root 5-tab shell for Phase 1.
///
/// Uses [IndexedStack] so each tab keeps its state (including the embedded
/// media-library [HomeScreen] under 「媒体库」).
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
  static const int _libraryTabIndex = 1;

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
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[
          HomeTabPage(),
          LibraryTabPage(),
          CalendarTabPage(),
          CentersTabPage(),
          MineTabPage(),
        ],
      ),
      // Phase 8: hide shell nav while Library multi-select shows its own
      // BottomAppBar — avoids stacking two bottom bars.
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: librarySelectionActive,
        builder: (context, selectionActive, _) {
          final hideForLibrarySelect =
              _currentIndex == _libraryTabIndex && selectionActive;
          if (hideForLibrarySelect) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabSelected,
            backgroundColor: const Color(0xFF1E1E1E),
            indicatorColor: Colors.blue.withValues(alpha: 0.24),
            destinations: [
              for (final tab in _tabs)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          );
        },
      ),
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
