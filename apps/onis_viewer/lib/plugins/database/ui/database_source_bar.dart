import 'package:flutter/material.dart';

import '../../../api/core/ov_api_core.dart';
import '../../../core/constants.dart';
import '../../../core/database_source.dart';

class DatabaseSourceBar extends StatefulWidget {
  final DatabaseSource? selectedSource;
  final ValueChanged<DatabaseSource>? onSourceSelected;
  final VoidCallback? onAddSource;
  final VoidCallback? onRefreshSources;

  const DatabaseSourceBar({
    super.key,
    this.selectedSource,
    this.onSourceSelected,
    this.onAddSource,
    this.onRefreshSources,
  });

  @override
  State<DatabaseSourceBar> createState() => _DatabaseSourceBarState();
}

class _DatabaseSourceBarState extends State<DatabaseSourceBar> {
  final OVApi _api = OVApi();
  late final DatabaseSourceManager _manager;
  final Set<String> _expanded = <String>{};
  DatabaseSource? _selected;

  @override
  void initState() {
    super.initState();
    _manager = _api.sources;
    _selected = widget.selectedSource;
    _manager.addListener(_onManagerChanged);
  }

  @override
  void didUpdateWidget(covariant DatabaseSourceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only override local selection if parent provides a non-null selection
    if (widget.selectedSource != null && widget.selectedSource != _selected) {
      _selected = widget.selectedSource;
    }
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _manager.removeListener(_onManagerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildSourcesTree()),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: OnisViewerConstants.tabBarColor,
        border: Border(
          bottom: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder,
            color: OnisViewerConstants.textColor,
            size: 20,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          const Expanded(
            child: Text(
              'Sources',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: OnisViewerConstants.textColor,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onRefreshSources,
            icon: const Icon(
              Icons.refresh,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Refresh sources',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: widget.onAddSource,
            icon: const Icon(
              Icons.add,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Add source',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTree() {
    final roots = _manager.rootSources;
    if (roots.isEmpty) {
      return const Center(
        child: Text(
          'No sources',
          style: TextStyle(color: OnisViewerConstants.textSecondaryColor),
        ),
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final source in roots) _buildSourceNode(source, depth: 0),
      ],
    );
  }

  Widget _buildSourceNode(DatabaseSource source, {required int depth}) {
    final isSelected = _selected?.uid == source.uid;
    final isExpanded = _expanded.contains(source.uid);
    final hasChildren = source.subSources.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(
            left: OnisViewerConstants.paddingMedium + (depth * 20),
            right: OnisViewerConstants.paddingMedium,
          ),
          leading: hasChildren
              ? IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    setState(() {
                      if (isExpanded) {
                        _expanded.remove(source.uid);
                      } else {
                        _expanded.add(source.uid);
                      }
                    });
                  },
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: isSelected
                        ? OnisViewerConstants.primaryColor
                        : OnisViewerConstants.textSecondaryColor,
                  ),
                )
              : const SizedBox(width: 18),
          title: Text(
            source.name,
            style: TextStyle(
              color: isSelected
                  ? OnisViewerConstants.primaryColor
                  : OnisViewerConstants.textColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          selected: isSelected,
          selectedTileColor:
              OnisViewerConstants.surfaceColor.withValues(alpha: 0.12),
          onTap: () {
            setState(() {
              _selected = source;
            });
            widget.onSourceSelected?.call(source);
          },
        ),
        if (hasChildren && isExpanded)
          for (final child in source.subSources)
            _buildSourceNode(child, depth: depth + 1),
      ],
    );
  }

  Widget _buildFooter() {
    final total = _manager.allSources.length;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: OnisViewerConstants.tabBarColor,
        border: Border(
          top: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: OnisViewerConstants.textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Text(
            '$total sources',
            style: const TextStyle(
              color: OnisViewerConstants.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
