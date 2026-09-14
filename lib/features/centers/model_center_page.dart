import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/system/model_center/model_center.dart';

/// Model Center skeleton — 转录 / 翻译 / 问答 sections.
class ModelCenterPage extends StatelessWidget {
  const ModelCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('模型中心'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Consumer<ModelCenter>(
        builder: (context, center, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _KindSection(kind: ModelKind.transcription, center: center),
              const SizedBox(height: 20),
              _KindSection(kind: ModelKind.translation, center: center),
              const SizedBox(height: 20),
              _KindSection(kind: ModelKind.qa, center: center),
            ],
          );
        },
      ),
    );
  }
}

class _KindSection extends StatelessWidget {
  const _KindSection({required this.kind, required this.center});

  final ModelKind kind;
  final ModelCenter center;

  @override
  Widget build(BuildContext context) {
    final models = center.list(kind);
    final activeId = center.getActive(kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kind.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (models.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '即将支持',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          )
        else
          ...models.map((m) {
            final selected = m.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: m.available
                      ? () => center.setActive(kind, m.id)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: selected ? Colors.lightBlueAccent : Colors.white38,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (m.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.description,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
