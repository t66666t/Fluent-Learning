import 'package:flutter/material.dart';
import 'package:fluent_learning/widgets/media_library_empty_state.dart';

import 'package:fluent_learning/models/video_collection.dart';
import 'package:fluent_learning/models/video_item.dart';
import 'package:fluent_learning/models/video_picker_tree_node.dart';
import 'package:fluent_learning/services/library_service.dart';
import 'package:fluent_learning/system/media_picker/media_picker_request.dart';
import 'package:fluent_learning/system/media_picker/media_picker_result.dart';

/// App-wide media library picker UI (Phase 2 system Media Picker).
///
/// Prefer [showAppMediaPicker] over constructing this dialog directly.
///
/// Phase 8: in-library search, interactive type filter chips, optional
/// dual-pane layout on wide screens.
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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  /// Interactive type filter; null / empty = all types.
  /// Initialized from [MediaPickerRequest.typeFilter] and refinable in UI.
  Set<MediaType>? _activeTypeFilter;

  /// Dual-pane: currently focused folder (null = root listing of leaves + folders).
  String? _paneFolderId;

  MediaPickerRequest get _request => widget.request;

  static const double _dualPaneBreakpoint = 720;

  @override
  void initState() {
    super.initState();
    _tree = VideoPickerTree();
    final initial = _request.typeFilter;
    if (initial != null && initial.isNotEmpty) {
      _activeTypeFilter = Set<MediaType>.from(initial);
    }
    _paneFolderId = _request.initialFolderId;
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      if (q == _searchQuery) return;
      setState(() => _searchQuery = q);
    });
    _loadTree();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    final filter = _activeTypeFilter;
    if (filter == null || filter.isEmpty) return true;
    return filter.contains(item.type);
  }

  List<VideoPickerTreeNode> _buildNodes(String? parentId) {
    final contents = widget.libraryService.getContents(parentId);
    final nodes = <VideoPickerTreeNode>[];

    for (final item in contents) {
      if (item is VideoCollection) {
        final children = _buildNodes(item.id);
        if ((_activeTypeFilter != null && _activeTypeFilter!.isNotEmpty) &&
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

  bool _nodeMatchesSearch(VideoPickerTreeNode node) {
    if (_searchQuery.isEmpty) return true;
    if (node.name.toLowerCase().contains(_searchQuery)) return true;
    if (node.isFolder) {
      return node.children.any(_nodeMatchesSearch);
    }
    return false;
  }

  List<VideoPickerTreeNode> _visibleRoots() {
    if (_searchQuery.isEmpty) return _tree.roots;
    return _tree.roots.where(_nodeMatchesSearch).toList(growable: false);
  }

  VideoPickerTreeNode? _findNode(String id) {
    VideoPickerTreeNode? walk(VideoPickerTreeNode n) {
      if (n.nodeId == id) return n;
      for (final c in n.children) {
        final found = walk(c);
        if (found != null) return found;
      }
      return null;
    }

    for (final root in _tree.roots) {
      final found = walk(root);
      if (found != null) return found;
    }
    return null;
  }

  List<VideoPickerTreeNode> _paneFolderNodes() {
    final folders = <VideoPickerTreeNode>[];
    void collect(VideoPickerTreeNode n) {
      if (n.isFolder) {
        folders.add(n);
        for (final c in n.children) {
          collect(c);
        }
      }
    }

    for (final root in _tree.roots) {
      collect(root);
    }
    return folders;
  }

  List<VideoPickerTreeNode> _paneContentNodes() {
    final folderId = _paneFolderId;
    final List<VideoPickerTreeNode> source;
    if (folderId == null) {
      source = _tree.roots;
    } else {
      final folder = _findNode(folderId);
      source = folder?.children ?? const <VideoPickerTreeNode>[];
    }
    if (_searchQuery.isEmpty) return source;
    return source.where(_nodeMatchesSearch).toList(growable: false);
  }

  void _setTypeFilter(Set<MediaType>? next) {
    final prevSelected = _tree
        .getSelectedLeaves()
        .map((n) => n.videoId)
        .whereType<String>()
        .toSet();
    setState(() {
      _activeTypeFilter = next;
      final roots = _buildNodes(null);
      _tree = VideoPickerTree(roots: roots);
      if (prevSelected.isNotEmpty) {
        void restore(VideoPickerTreeNode n) {
          if (!n.isFolder &&
              n.videoId != null &&
              prevSelected.contains(n.videoId) &&
              !n.isAlreadyInQueue) {
            n.isSelected = true;
          }
          for (final c in n.children) {
            restore(c);
          }
        }

        for (final root in _tree.roots) {
          restore(root);
        }
      }
      _tree.recalculateCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedLeaves = _tree.getSelectedLeaves();
    final canConfirm = selectedLeaves.isNotEmpty;
    final title = _request.title ?? '选择媒体';
    final confirmLabel = _request.confirmLabel ?? '确认';
    final width = MediaQuery.of(context).size.width;
    final useDualPane = width >= _dualPaneBreakpoint;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: width * (useDualPane ? 0.9 : 0.85),
        height: MediaQuery.of(context).size.height * 0.65,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _tree.roots.isEmpty && _searchQuery.isEmpty
            ? const MediaLibraryEmptyState.pickerEmpty()
            : Column(
                children: [
                  _buildToolbar(),
                  const Divider(height: 1),
                  Expanded(
                    child: useDualPane
                        ? _buildDualPane()
                        : _buildTreeList(_visibleRoots()),
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

  Widget _buildToolbar() {
    final lockedByRequest =
        _request.typeFilter != null && _request.typeFilter!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          const SizedBox(height: 4),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              isDense: true,
              hintText: '搜索媒体库…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清除',
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                lockedByRequest ? '类型（请求限定）' : '类型',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).hintColor,
                ),
              ),
              _typeChip(
                label: '全部',
                selected:
                    _activeTypeFilter == null || _activeTypeFilter!.isEmpty,
                onSelected: lockedByRequest
                    ? null
                    : (_) => _setTypeFilter(null),
              ),
              _typeChip(
                label: '视频',
                selected:
                    _activeTypeFilter != null &&
                    _activeTypeFilter!.length == 1 &&
                    _activeTypeFilter!.contains(MediaType.video),
                enabled:
                    !lockedByRequest ||
                    (_request.typeFilter?.contains(MediaType.video) ?? true),
                onSelected: (v) {
                  if (lockedByRequest &&
                      !(_request.typeFilter?.contains(MediaType.video) ??
                          true)) {
                    return;
                  }
                  if (v) {
                    _setTypeFilter({MediaType.video});
                  } else if (!lockedByRequest) {
                    _setTypeFilter(null);
                  }
                },
              ),
              _typeChip(
                label: '音频',
                selected:
                    _activeTypeFilter != null &&
                    _activeTypeFilter!.length == 1 &&
                    _activeTypeFilter!.contains(MediaType.audio),
                enabled:
                    !lockedByRequest ||
                    (_request.typeFilter?.contains(MediaType.audio) ?? true),
                onSelected: (v) {
                  if (lockedByRequest &&
                      !(_request.typeFilter?.contains(MediaType.audio) ??
                          true)) {
                    return;
                  }
                  if (v) {
                    _setTypeFilter({MediaType.audio});
                  } else if (!lockedByRequest) {
                    _setTypeFilter(null);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required bool selected,
    required ValueChanged<bool>? onSelected,
    bool enabled = true,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? onSelected : null,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildDualPane() {
    final folders = _paneFolderNodes();
    final contents = _paneContentNodes();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  '文件夹',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      dense: true,
                      selected: _paneFolderId == null,
                      leading: const Icon(Icons.home_outlined, size: 18),
                      title: const Text('根目录', style: TextStyle(fontSize: 13)),
                      onTap: () => setState(() => _paneFolderId = null),
                    ),
                    for (final folder in folders)
                      ListTile(
                        dense: true,
                        selected: _paneFolderId == folder.nodeId,
                        leading: Icon(
                          Icons.folder,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                        title: Text(
                          folder.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () =>
                            setState(() => _paneFolderId = folder.nodeId),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: contents.isEmpty
              ? (_searchQuery.isEmpty
                  ? const MediaLibraryEmptyState.pickerFolderEmpty()
                  : const MediaLibraryEmptyState.searchNoResults(compact: true))
              : ListView.builder(
                  itemCount: contents.length,
                  itemBuilder: (ctx, index) {
                    final node = contents[index];
                    if (node.isFolder) {
                      return _buildNodeRow(node, 0, dualPaneFolderNav: true);
                    }
                    return _buildNodeRow(node, 0);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTreeList(List<VideoPickerTreeNode> roots) {
    if (roots.isEmpty) {
      return _searchQuery.isEmpty
          ? const MediaLibraryEmptyState.pickerEmpty()
          : const MediaLibraryEmptyState.searchNoResults(compact: true);
    }
    return ListView.builder(
      itemCount: roots.length,
      itemBuilder: (ctx, index) {
        return _buildTreeNode(roots[index], 0);
      },
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
    if (_searchQuery.isNotEmpty && !_nodeMatchesSearch(node)) {
      return const SizedBox.shrink();
    }
    if (node.isFolder) {
      final isExpanded =
          _searchQuery.isNotEmpty || _expandedFolders.contains(node.nodeId);
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

  void _toggleNode(VideoPickerTreeNode node, {bool dualPaneFolderNav = false}) {
    if (dualPaneFolderNav && node.isFolder) {
      setState(() => _paneFolderId = node.nodeId);
      return;
    }
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

  Widget _buildNodeRow(
    VideoPickerTreeNode node,
    int depth, {
    bool dualPaneFolderNav = false,
  }) {
    final checkboxValue = node.isSelected
        ? true
        : node.isIndeterminate
        ? null
        : false;
    final showCheckbox =
        !node.isFolder || (_request.allowFolders && _request.multiSelect);

    return InkWell(
      onTap: () => _toggleNode(node, dualPaneFolderNav: dualPaneFolderNav),
      child: Padding(
        padding: EdgeInsets.only(left: depth * 24.0 + 8.0),
        child: Row(
          children: [
            if (node.isFolder && !dualPaneFolderNav)
              IconButton(
                icon: Icon(
                  (_searchQuery.isNotEmpty ||
                          _expandedFolders.contains(node.nodeId))
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
            if (dualPaneFolderNav && node.isFolder)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.chevron_right, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
