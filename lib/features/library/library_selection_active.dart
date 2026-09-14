import 'package:flutter/foundation.dart';

/// Whether the Library tab ([HomeScreen] / [CollectionScreen]) is in
/// multi-select mode.
///
/// [MainShell] listens so it can hide its [NavigationBar] and avoid stacking
/// two bottom bars (Phase 8 dual-Scaffold fix; Phase 16 regression guard).
final ValueNotifier<bool> librarySelectionActive = ValueNotifier<bool>(false);
