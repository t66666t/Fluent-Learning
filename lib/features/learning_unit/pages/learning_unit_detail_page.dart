import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:fluent_learning/features/learning_unit/data/learning_unit_repository.dart';
import 'package:fluent_learning/features/learning_unit/models/learning_unit.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/services/playback_navigation_service.dart';
import 'package:fluent_learning/services/playlist_manager.dart';
import 'package:fluent_learning/system/feedback/feedback.dart';

/// Detail / execution page: item list, progress, open playback, mark complete.
class LearningUnitDetailPage extends StatefulWidget {
  const LearningUnitDetailPage({
    super.key,
    required this.unitId,
    this.autoContinueLearning = false,
  });

  final String unitId;

  /// When true, after first frame open next incomplete media via
  /// [PlaybackNavigationService] (home primary「继续学」path).
  final bool autoContinueLearning;

  @override
  State<LearningUnitDetailPage> createState() => _LearningUnitDetailPageState();
}

class _LearningUnitDetailPageState extends State<LearningUnitDetailPage>
    with AppInlineFeedbackMixin {
  bool _didAutoContinue = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoContinueLearning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoContinue) return;
        _didAutoContinue = true;
        final repo = context.read<LearningUnitRepository>();
        final library = context.read<LibraryService>();
        final unit = repo.getById(widget.unitId);
        if (unit == null) return;
        _continueNext(repo, library, unit);
      });
    }
  }

  Future<void> _openPlayback(VideoItem item) async {
    final playlist = context.read<PlaylistManager>();
    if (!playlist.matchesFolderPlaylist(item.parentId, item.id)) {
      playlist.loadFolderPlaylist(item.parentId, item.id);
    }
    await Navigator.of(context).push(
      PlaybackNavigationService.buildPlaybackEntryRoute(item),
    );
  }

  Future<void> _continueNext(
    LearningUnitRepository repo,
    LibraryService library,
    LearningUnit unit,
  ) async {
    final nextId = repo.nextIncompleteMediaId(unit);
    if (nextId == null) return;
    final video = library.getVideo(nextId);
    if (video == null) return;
    await _openPlayback(video);
  }

  Future<void> _toggleLeafComplete(
    LearningUnitRepository repo,
    String mediaId,
    bool currentlyDone,
  ) async {
    final markingDone = !currentlyDone;
    await repo.markMediaComplete(
      widget.unitId,
      mediaId,
      completed: markingDone,
    );
    if (!mounted) return;
    showInlineFeedback(
      markingDone
          ? AppFeedbackMessage.success('已标记完成', title: '进度更新')
          : AppFeedbackMessage.info('已取消完成', title: '进度更新'),
    );
  }

  Future<void> _onUnitAction(
    _UnitAction action,
    LearningUnitRepository repo,
    LearningUnit unit,
  ) async {
    switch (action) {
      case _UnitAction.pause:
        await repo.setStatus(widget.unitId, LearningUnitStatus.paused);
        if (!mounted) return;
        showInlineFeedback(
          AppFeedbackMessage.info('单元已暂停', title: '状态更新'),
        );
      case _UnitAction.resume:
        await repo.setStatus(widget.unitId, LearningUnitStatus.active);
        if (!mounted) return;
        showInlineFeedback(
          AppFeedbackMessage.success('已恢复学习', title: '状态更新'),
        );
      case _UnitAction.complete:
        await repo.setStatus(widget.unitId, LearningUnitStatus.completed);
        if (!mounted) return;
        showInlineFeedback(
          AppFeedbackMessage.success('单元已标记完成', title: '完成'),
        );
      case _UnitAction.editDue:
        await _editDueDate(repo, unit);
      case _UnitAction.clearDue:
        await repo.update(
          unit.copyWith(
            schedule: unit.schedule.copyWith(clearDueDate: true),
          ),
        );
        if (!mounted) return;
        showInlineFeedback(
          AppFeedbackMessage.info('已清除截止日期', title: '日程'),
        );
      case _UnitAction.archive:
        await repo.softDelete(widget.unitId);
        if (mounted) Navigator.of(context).pop();
    }
  }

  /// Incomplete items first; stable within each group.
  List<String> _sortedMediaIds(
    LearningUnitRepository repo,
    LearningUnit unit,
    List<String> mediaIds,
  ) {
    final incomplete = <String>[];
    final complete = <String>[];
    for (final id in mediaIds) {
      if (repo.isLeafComplete(unit, id)) {
        complete.add(id);
      } else {
        incomplete.add(id);
      }
    }
    return [...incomplete, ...complete];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LearningUnitRepository, LibraryService>(
      builder: (context, repo, library, _) {
        final unit = repo.getById(widget.unitId);
        if (unit == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(
              title: const Text('学习单元'),
              backgroundColor: const Color(0xFF1E1E1E),
              elevation: 0,
            ),
            body: const Center(
              child: Text(
                '单元不存在或已删除',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final mediaIds = _sortedMediaIds(repo, unit, repo.resolveMediaIds(unit));
        final completedCount = repo.completedLeafCount(unit);
        final percentLabel =
            '${(unit.progress.percent * 100).clamp(0, 100).toStringAsFixed(0)}%';
        final nextId = repo.nextIncompleteMediaId(unit);
        final banner = buildInlineFeedbackBanner(dense: true);

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text(unit.title),
            backgroundColor: const Color(0xFF1E1E1E),
            elevation: 0,
            actions: [
              PopupMenuButton<_UnitAction>(
                onSelected: (action) => _onUnitAction(action, repo, unit),
                itemBuilder: (context) => [
                  if (unit.status != LearningUnitStatus.paused)
                    const PopupMenuItem(
                      value: _UnitAction.pause,
                      child: Text('暂停'),
                    ),
                  if (unit.status == LearningUnitStatus.paused ||
                      unit.status == LearningUnitStatus.planned)
                    const PopupMenuItem(
                      value: _UnitAction.resume,
                      child: Text('继续'),
                    ),
                  if (unit.status != LearningUnitStatus.completed)
                    const PopupMenuItem(
                      value: _UnitAction.complete,
                      child: Text('标记完成'),
                    ),
                  PopupMenuItem(
                    value: _UnitAction.editDue,
                    child: Text(
                      unit.schedule.dueDate == null ? '设置截止日期' : '修改截止日期',
                    ),
                  ),
                  if (unit.schedule.dueDate != null)
                    const PopupMenuItem(
                      value: _UnitAction.clearDue,
                      child: Text('清除截止日期'),
                    ),
                  const PopupMenuItem(
                    value: _UnitAction.archive,
                    child: Text('归档删除'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (banner != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: banner,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(status: unit.status),
                        const SizedBox(width: 10),
                        Text(
                          '$percentLabel · $completedCount/${mediaIds.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _editDueDate(repo, unit),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: unit.schedule.dueDate == null
                                  ? Colors.white38
                                  : _dueColor(unit.schedule.dueDate!),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              unit.schedule.dueDate == null
                                  ? '点击设置截止日期'
                                  : '截止 ${_fmtDate(unit.schedule.dueDate!)}',
                              style: TextStyle(
                                color: unit.schedule.dueDate == null
                                    ? Colors.white38
                                    : _dueColor(unit.schedule.dueDate!),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              size: 14,
                              color: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (unit.notes != null && unit.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        unit.notes!,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: unit.progress.percent.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    if (nextId != null && library.getVideo(nextId) != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _continueNext(repo, library, unit),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('继续学习'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: mediaIds.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无媒体（文件夹可能为空或已删除）',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: mediaIds.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (context, index) {
                          final id = mediaIds[index];
                          final video = library.getVideo(id);
                          final done = repo.isLeafComplete(unit, id);
                          final manual =
                              repo.isLeafManuallyCompleted(unit, id);
                          final itemRatio = repo.leafRatio(unit, id);
                          final itemPct = (itemRatio * 100)
                              .clamp(0, 100)
                              .toStringAsFixed(0);
                          final title = video?.title ?? '未知媒体 ($id)';
                          final duration =
                              _durationLabel(video?.durationMs ?? 0);

                          return ListTile(
                            leading: Icon(
                              done
                                  ? Icons.check_circle
                                  : Icons.play_circle_outline,
                              color: done
                                  ? Colors.greenAccent
                                  : Colors.lightBlueAccent,
                            ),
                            title: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: done ? Colors.white54 : Colors.white,
                                decoration: done
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (duration.isNotEmpty)
                                    Text(
                                      duration,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: itemRatio.clamp(0.0, 1.0),
                                            minHeight: 4,
                                            backgroundColor: Colors.white12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$itemPct%',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            trailing: (done && !manual)
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white24,
                                  )
                                : IconButton(
                                    tooltip: done ? '取消完成' : '标记完成',
                                    icon: Icon(
                                      done ? Icons.undo : Icons.check,
                                      color: Colors.white38,
                                    ),
                                    onPressed: () =>
                                        _toggleLeafComplete(repo, id, done),
                                  ),
                            onTap: video == null
                                ? null
                                : () => _openPlayback(video),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editDueDate(
    LearningUnitRepository repo,
    LearningUnit unit,
  ) async {
    final now = DateTime.now();
    final current = unit.schedule.dueDate;
    final initial = current ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(now.year - 1))
          ? now
          : initial,
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
    final due = DateTime(picked.year, picked.month, picked.day, 23, 59);
    await repo.update(
      unit.copyWith(
        schedule: unit.schedule.copyWith(dueDate: due),
      ),
    );
    if (!mounted) return;
    showInlineFeedback(
      AppFeedbackMessage.success('截止日期已更新', title: '日程'),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Color _dueColor(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    if (dueDay.isBefore(today)) return Colors.redAccent;
    if (dueDay.difference(today).inDays <= 2) return Colors.orangeAccent;
    return Colors.white54;
  }

  static String _durationLabel(int ms) {
    if (ms <= 0) return '';
    final totalSec = ms ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final mm = m % 60;
      return '$h:${mm.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

enum _UnitAction { pause, resume, complete, editDue, clearDue, archive }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LearningUnitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.labelZh,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}
