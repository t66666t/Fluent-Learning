import 'package:flutter/material.dart';

/// 「我的」Tab — Phase 1 placeholder.
class MineTabPage extends StatelessWidget {
  const MineTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('我的'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '我的',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
