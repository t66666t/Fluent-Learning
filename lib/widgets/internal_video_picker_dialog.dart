import 'package:flutter/material.dart';

import 'package:fluent_learning/models/video_collection.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/models/video_picker_tree_node.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/media_picker/media_picker_request.dart';
import 'package:fluent_learning/system/media_picker/media_picker_result.dart';

/// App-wide media library picker UI (Phase 2 system Media Picker).
///
/// Prefer [showAppMediaPicker] over constructing this dialog directly.
class InternalVideoPickerDialog extends StatefulWidget {
  final LibraryService libraryService;
  final MediaPickerRequest request;

  const InternalVideoPickerDialog({
    super.key,
    required this.libraryService,
    this.request = const MediaPickerRequest(),
  });

  @override
  State<InternalVideoPickerDialog> createState() =>
      _InternalVideoPickerDialogState();
}

class _InternalVideoPickerDialogState extends State<InternalVideoPickerDialog> {
  late VideoPickerTree _tree;
  final Set<String> _expandedFolders = {};
  bool _isLoading = true;

  MediaPickerRequest get _request => widget.request;

  @override
  void initState() {
    super.initState();
    _tree = VideoPickerTree();
    _loadTree();
  }

  void _loadTree() {
    setState(() => _isLoading = true);
    final roots = _buildNodes(null);
    _tree = VideoPickerTree(roots: roots);
    final initial = _request.initialFolderId;
    if (initial != null) {
      _expandedFolders.add(initial);
    }
    _tree.recalculateCounts();
    setState(() => _isLoading = false);
  }

  bool _passesTypeFilter(VideoItem item) {
    final filter = _request.typeFilter;
    if (filter == null || filter.isEmpty) return true;
    return filter.contains(item.type);
  }

  List<VideoPickerTreeNode> _buildNodes(String? parentId) {
    final contents = widget.libraryService.getContents(parentId);
    final nodes = <VideoPickerTreeNode>[];

    for (final item in contents) {
      if (item is VideoCollection) {
        final children = _buildNodes(item.id);
        // Prune empty folders when a type filter removed all leaves.
        if ((_request.typeFilter != null &&
                _request.typeFilter!.isNotEmpty) &&
            children.isEmpty) {
          continue;
        }
        nodes.add(
          VideoPickerTreeNode(
            nodeId: item.id,
            name: item.name,
            isFolder: true,
            parentId: parentId,
            children: children,
          ),
        );
      } else if (item is VideoItem) {
        if (!_passesTypeFilter(item)) continue;
        final excluded = _request.excludeIds.contains(item.id);
        final duration = _formatDuration(item.durationMs);
        nodes.add(
          VideoPickerTreeNode(
            nodeId: item.id,
            name: item.title,
            isFolder: false,
            parentId: parentId,
            videoId: item.id,
            videoPath: item.path,
            videoDuration: duration,
            isAlreadyInQueue: excluded,
          ),
        );
      }
    }

    return nodes;
  }

  String _formatDuration(int ms) {
    if (ms <= 0) return '';
    final h = ms ~/ 3600000;
    final m = (ms % 3600000) ~/ 60000;
    final s = (ms % 60000) ~/ 1000;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  MediaPickerResult _buildResult() {
    final leaves = _tree.getSelectedLeaves();
    final folders = _request.allowFolders
        ? _tree.getSelectedFolders()
        : const <VideoPickerTreeNode>[];
    return MediaPickerResult(
      mediaIds: leaves
          .map((n) => n.videoId)
          .whereType<String>()
          .toList(growable: false),
      folderIds: folders.map((n) => n.nodeId).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLeaves = _tree.getSelectedLeaves();
    final canConfirm = selectedLeaves.isNotEmpty;
    final title = _request.title ?? '选择媒体';
    final confirmLabel = _request.confirmLabel ?? '确认';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.65,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tree.roots.isEmpty
            ? const Center(child: Text('暂无媒体，请先导入视频或音频'))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '已选择 ${_tree.selectedCount} 个媒体',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        if (_request.multiSelect) ...[
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (final root in _tree.roots) {
                                  _selectAll(root, true);
                                }
                                _tree.recalculateCounts();
                              });
                            },
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                for (final root in _tree.roots) {
                                  _selectAll(root, false);
                                }
                                _tree.recalculateCounts();
                              });
                            },
                            child: const Text('取消全选'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _tree.roots.length,
                      itemBuilder: (ctx, index) {
                        return _buildTreeNode(_tree.roots[index], 0);
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.pop(context, _buildResult())
              : null,
          child: Text('$confirmLabel (${selectedLeaves.length})'),
        ),
      ],
    );
  }

  void _selectAll(VideoPickerTreeNode node, bool selected) {
    if (node.isAlreadyInQueue && !node.isFolder) return;
    if (node.isFolder) {
      node.isSelected = selected && _request.allowFolders;
      node.isIndeterminate = false;
      for (final child in node.children) {
        _selectAll(child, selected);
      }
    } else {
      node.isSelected = selected;
      node.isIndeterminate = false;
    }
  }

  Widget _buildTreeNode(VideoPickerTreeNode node, int depth) {
    if (node.isFolder) {
      final isExpanded = _expandedFolders.contains(node.nodeId);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNodeRow(node, depth),
          if (isExpanded)
            ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
        ],
      );
    }
    return _buildNodeRow(node, depth);
  }

  bool _canToggle(VideoPickerTreeNode node) {
    if (node.isAlreadyInQueue) return false;
    if (node.isFolder && (!_request.allowFolders || !_request.multiSelect)) {
      return false;
    }
    return true;
  }

  void _toggleNode(VideoPickerTreeNode node) {
    if (!_canToggle(node)) {
      if (node.isFolder) {
        setState(() {
          if (_expandedFolders.contains(node.nodeId)) {
            _expandedFolders.remove(node.nodeId);
          } else {
            _expandedFolders.add(node.nodeId);
          }
        });
      }
      return;
    }
    setState(() {
      _tree.updateSelection(
        node,
        !node.isSelected,
        multiSelect: _request.multiSelect,
      );
    });
  }

  Widget _buildNodeRow(VideoPickerTreeNode node, int depth) {
    final checkboxValue = node.isSelected
        ? true
        : node.isIndeterminate
        ? null
        : false;
    final showCheckbox = !node.isFolder || (_request.allowFolders && _request.multiSelect);

    return InkWell(
      onTap: () => _toggleNode(node),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 24.0 + 8.0),
        child: Row(
          children: [
            if (node.isFolder)
              IconButton(
                icon: Icon(
                  _expandedFolders.contains(node.nodeId)
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (_expandedFolders.contains(node.nodeId)) {
                      _expandedFolders.remove(node.nodeId);
                    } else {
                      _expandedFolders.add(node.nodeId);
                    }
                  });
                },
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            if (showCheckbox)
              Checkbox(
                value: checkboxValue,
                tristate: true,
                onChanged: !_canToggle(node)
                    ? null
                    : (v) {
                        setState(() {
                          _tree.updateSelection(
                            node,
                            v ?? false,
                            multiSelect: _request.multiSelect,
                          );
                        });
                      },
              )
            else
              const SizedBox(width: 48),
            Icon(
              node.isFolder ? Icons.folder : Icons.play_circle_outline,
              size: 18,
              color: node.isFolder
                  ? Colors.amber.shade700
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: node.isAlreadyInQueue
                          ? Theme.of(context).disabledColor
                          : null,
                    ),
                  ),
                  if (!node.isFolder && node.videoDuration != null)
                    Text(
                      node.videoDuration!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                ],
              ),
            ),
            if (node.isAlreadyInQueue)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  '不可选',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
