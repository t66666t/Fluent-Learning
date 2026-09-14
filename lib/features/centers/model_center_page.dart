import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/library/media_prompt_builder.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';
import 'package:fluent_learning/system/model_center/model_center.dart';

/// Model Center — 转录 / 翻译 / 问答；切换会持久化并影响下一次任务。
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
              const Text(
                '切换下方模型后立即写入设置；下一次转录 / 翻译任务会读取当前激活项。',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _KindSection(kind: ModelKind.transcription, center: center),
              const SizedBox(height: 20),
              _KindSection(kind: ModelKind.translation, center: center),
              const SizedBox(height: 20),
              _KindSection(kind: ModelKind.qa, center: center),
              const SizedBox(height: 20),
              const _QaPromptPreviewCard(),
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
    final active = center.resolve(kind);
    final config = center.getRemoteConfig(kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              kind.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: active != null
                      ? Colors.lightBlueAccent.withValues(alpha: 0.18)
                      : Colors.orange.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active != null
                        ? Colors.lightBlueAccent.withValues(alpha: 0.45)
                        : Colors.orange.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  active != null
                      ? '当前：${active.displayName}'
                      : (kind == ModelKind.qa ? '未配置' : '未配置可用模型'),
                  style: TextStyle(
                    color: active != null
                        ? Colors.lightBlueAccent
                        : Colors.orangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (models.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.35),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '未配置',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '问答模型尚未接入。可在下方预览 MediaPromptBuilder 生成的提示词，'
                  '并预留本地模型 / API 配置。',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...models.map((m) {
            final selected = m.id == activeId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? const Color(0xFF243041)
                    : const Color(0xFF1E1E1E),
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
                          color: !m.available
                              ? Colors.white24
                              : (selected
                                  ? Colors.lightBlueAccent
                                  : Colors.white38),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      m.displayName,
                                      style: TextStyle(
                                        color: m.available
                                            ? Colors.white
                                            : Colors.white38,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (selected) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      '使用中',
                                      style: TextStyle(
                                        color: Colors.lightBlueAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  if (!m.available) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      '预留',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (m.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  m.description,
                                  style: TextStyle(
                                    color: m.available
                                        ? Colors.white54
                                        : Colors.white30,
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
        const SizedBox(height: 4),
        _RemoteConfigTile(kind: kind, center: center, config: config),
      ],
    );
  }
}

class _RemoteConfigTile extends StatefulWidget {
  const _RemoteConfigTile({
    required this.kind,
    required this.center,
    required this.config,
  });

  final ModelKind kind;
  final ModelCenter center;
  final ModelKindRemoteConfig config;

  @override
  State<_RemoteConfigTile> createState() => _RemoteConfigTileState();
}

class _RemoteConfigTileState extends State<_RemoteConfigTile> {
  late final TextEditingController _localPath;
  late final TextEditingController _apiBase;
  late final TextEditingController _apiKey;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _localPath = TextEditingController(text: widget.config.localModelPath);
    _apiBase = TextEditingController(text: widget.config.apiBaseUrl);
    _apiKey = TextEditingController(text: widget.config.apiKey);
    _expanded = widget.config.hasAny;
  }

  @override
  void didUpdateWidget(covariant _RemoteConfigTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.localModelPath != widget.config.localModelPath &&
        _localPath.text != widget.config.localModelPath) {
      _localPath.text = widget.config.localModelPath;
    }
    if (oldWidget.config.apiBaseUrl != widget.config.apiBaseUrl &&
        _apiBase.text != widget.config.apiBaseUrl) {
      _apiBase.text = widget.config.apiBaseUrl;
    }
    if (oldWidget.config.apiKey != widget.config.apiKey &&
        _apiKey.text != widget.config.apiKey) {
      _apiKey.text = widget.config.apiKey;
    }
  }

  @override
  void dispose() {
    _localPath.dispose();
    _apiBase.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await widget.center.setRemoteConfig(
      widget.kind,
      ModelKindRemoteConfig(
        localModelPath: _localPath.text.trim(),
        apiBaseUrl: _apiBase.text.trim(),
        apiKey: _apiKey.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            '本地模型 / API 配置（预留）'
            '${widget.config.hasAny ? ' · 已填写' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white38,
          children: [
            TextField(
              controller: _localPath,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: '本地模型路径',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: '/path/to/model.bin',
                hintStyle: TextStyle(color: Colors.white24),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiBase,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: 'https://api.example.com/v1',
                hintStyle: TextStyle(color: Colors.white24),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKey,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(color: Colors.white54),
                hintText: '仅本地保存，暂不调用',
                hintStyle: TextStyle(color: Colors.white24),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('保存配置'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Q&A prompt preview via [MediaPromptBuilder] — pick media or sample fields.
class _QaPromptPreviewCard extends StatefulWidget {
  const _QaPromptPreviewCard();

  @override
  State<_QaPromptPreviewCard> createState() => _QaPromptPreviewCardState();
}

class _QaPromptPreviewCardState extends State<_QaPromptPreviewCard> {
  final _titleController = TextEditingController(text: '示例媒体标题');
  final _fileNameController = TextEditingController(text: 'sample_video.mp4');
  final _durationController = TextEditingController(text: '125000');
  String? _pickedMediaId;
  String? _pickedMediaLabel;
  String _preview = '';

  @override
  void dispose() {
    _titleController.dispose();
    _fileNameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  VideoItem _sampleItem() {
    final durationMs = int.tryParse(_durationController.text.trim()) ?? 0;
    return VideoItem(
      id: 'qa_sample',
      path: '/sample/${_fileNameController.text.trim().isEmpty ? 'sample.mp4' : _fileNameController.text.trim()}',
      title: _titleController.text.trim().isEmpty
          ? '未命名'
          : _titleController.text.trim(),
      durationMs: durationMs < 0 ? 0 : durationMs,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      fileName: _fileNameController.text.trim().isEmpty
          ? null
          : _fileNameController.text.trim(),
      type: MediaType.video,
    );
  }

  void _rebuildFromSample() {
    setState(() {
      _pickedMediaId = null;
      _pickedMediaLabel = null;
      _preview = MediaPromptBuilder.from(_sampleItem());
    });
  }

  Future<void> _pickMedia() async {
    final result = await showAppMediaPicker(
      context,
      const MediaPickerRequest(
        multiSelect: false,
        allowFolders: false,
        title: '选择媒体以预览问答 Prompt',
        confirmLabel: '预览',
      ),
    );
    if (!mounted || result == null || result.mediaIds.isEmpty) return;
    final id = result.mediaIds.first;
    final library = context.read<LibraryService>();
    final item = library.getVideo(id);
    if (item == null) return;
    setState(() {
      _pickedMediaId = id;
      _pickedMediaLabel = item.effectiveDisplayName;
      _preview = MediaPromptBuilder.from(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '问答 Prompt 预览',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '问答模型未配置时，可先用 MediaPromptBuilder 生成提示词文本预览。',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: '示例标题',
              labelStyle: TextStyle(color: Colors.white54),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fileNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: '示例文件名',
              labelStyle: TextStyle(color: Colors.white54),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: '时长 (ms)',
              labelStyle: TextStyle(color: Colors.white54),
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _rebuildFromSample,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('用示例字段生成'),
              ),
              OutlinedButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.video_library_outlined, size: 16),
                label: const Text('从媒体库选择'),
              ),
            ],
          ),
          if (_pickedMediaLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              '已选媒体：$_pickedMediaLabel'
              '${_pickedMediaId == null ? '' : ' ($_pickedMediaId)'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (_preview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SelectableText(
                _preview,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
