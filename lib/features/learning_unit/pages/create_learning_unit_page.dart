import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/features/learning_unit/pages/learning_unit_detail_page.dart';
import 'package:fluent_learning/system/media_picker/media_picker.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';
import 'package:fluent_learning/core/theme_tokens.dart';

/// Create flow: title → media picker → optional due date → save.
class CreateLearningUnitPage extends StatefulWidget {
  const CreateLearningUnitPage({super.key});

  @override
  State<CreateLearningUnitPage> createState() => _CreateLearningUnitPageState();
}

class _CreateLearningUnitPageState extends State<CreateLearningUnitPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  List<String> _mediaIds = const <String>[];
  List<String> _folderIds = const <String>[];
  DateTime? _dueDate;
  bool _saving = false;
  AppFeedbackMessage? _statusFeedback;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final result = await showAppMediaPicker(
      context,
      const MediaPickerRequest(
        multiSelect: true,
        allowFolders: true,
        title: '选择学习内容',
        confirmLabel: '加入单元',
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _mediaIds = List<String>.from(result.mediaIds);
      _folderIds = List<String>.from(result.folderIds);
      _statusFeedback = AppFeedbackMessage.info(
        '已选媒体 ${_mediaIds.length}'
        '${_folderIds.isEmpty ? '' : '，文件夹 ${_folderIds.length}'}',
      );
    });
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: '选择截止日期',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted || picked == null) return;
    setState(() {
      _dueDate = DateTime(picked.year, picked.month, picked.day, 23, 59);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(
        () => _statusFeedback = AppFeedbackMessage.error('请填写标题', title: '无法保存'),
      );
      return;
    }
    if (_mediaIds.isEmpty && _folderIds.isEmpty) {
      setState(
        () => _statusFeedback =
            AppFeedbackMessage.error('请选择媒体或文件夹', title: '无法保存'),
      );
      return;
    }

    setState(() {
      _saving = true;
      _statusFeedback = AppFeedbackMessage.loading('正在保存学习单元…', title: '保存');
    });

    try {
      final repo = context.read<LearningUnitRepository>();
      final refs = <LearningUnitItemRef>[
        ..._folderIds.map(
          (id) => LearningUnitItemRef.folder(id, includeNested: true),
        ),
        // Keep leaf media refs that are not solely covered by folder bookkeeping.
        ..._mediaIds.map(LearningUnitItemRef.media),
      ];

      final unit = await repo.create(
        title: title,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        itemRefs: refs,
        schedule: LearningUnitSchedule(dueDate: _dueDate),
        status: LearningUnitStatus.active,
      );

      if (!mounted) return;
      // Inline success flash before navigation (no floating toast).
      setState(() {
        _statusFeedback = AppFeedback.saveSuccess('学习单元已保存，正在打开…');
      });
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LearningUnitDetailPage(unitId: unit.id),
          settings: RouteSettings(name: '/learning_unit/${unit.id}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _statusFeedback =
            AppFeedbackMessage.error('保存失败: $e', title: '保存失败');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_saving &&
        _titleController.text.trim().isNotEmpty &&
        (_mediaIds.isNotEmpty || _folderIds.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('新建学习单元'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: '标题',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ActionTile(
            icon: Icons.library_add_outlined,
            title: '选择媒体 / 文件夹',
            subtitle: _mediaIds.isEmpty && _folderIds.isEmpty
                ? '尚未选择'
                : '媒体 ${_mediaIds.length}'
                    '${_folderIds.isEmpty ? '' : ' · 文件夹 ${_folderIds.length}'}',
            onTap: _saving ? null : _pickMedia,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.event_outlined,
            title: '截止日期（可选）',
            subtitle: _dueDate == null
                ? '未设置'
                : '${_dueDate!.year}-'
                    '${_dueDate!.month.toString().padLeft(2, '0')}-'
                    '${_dueDate!.day.toString().padLeft(2, '0')}',
            trailing: _dueDate == null
                ? null
                : IconButton(
                    tooltip: '清除',
                    onPressed: _saving
                        ? null
                        : () => setState(() => _dueDate = null),
                    icon: const Icon(Icons.clear, color: Colors.white38),
                  ),
            onTap: _saving ? null : _pickDueDate,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadii.borderMd,
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存并打开'),
          ),
          if (_statusFeedback != null) ...[
            const SizedBox(height: 12),
            AppInlineBanner(message: _statusFeedback!),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: AppRadii.borderMd,
      child: InkWell(
        borderRadius: AppRadii.borderMd,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.lightBlueAccent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
