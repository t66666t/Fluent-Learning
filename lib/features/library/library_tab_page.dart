import 'package:flutter/material.dart';
import 'package:fluent_learning/screens/home_screen.dart';

/// 「媒体库」Tab — Phase 1 embeds the existing [HomeScreen] as-is.
///
/// Playback entry, import, and library UI stay on [HomeScreen] with
/// minimal wrapping so behavior is preserved.
class LibraryTabPage extends StatelessWidget {
  const LibraryTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
