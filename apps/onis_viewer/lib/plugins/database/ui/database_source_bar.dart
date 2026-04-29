import 'package:flutter/material.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';

import '../../../api/core/ov_api_core.dart';
import '../../../core/constants.dart';
import '../../../core/database_source.dart';
import 'database_theme.dart';

class DatabaseSourceBar extends StatefulWidget {
  //final DatabaseSource? selectedSource;
  //final ValueChanged<DatabaseSource>? onSourceSelected;
  //final VoidCallback? onAddSource;
//  final VoidCallback? onRefreshSources;

  const DatabaseSourceBar({
    super.key,
    //this.selectedSource,
    //this.onSourceSelected,
    //this.onAddSource,
    //this.onRefreshSources,
  });

  @override
  State<DatabaseSourceBar> createState() => _DatabaseSourceBarState();

  /// Static method to expand a node by UID
  static void expandNode(String uid, {bool expandChildren = false}) {
    _DatabaseSourceBarState.expandNode(uid, expandChildren: expandChildren);
  }

  /// Static method to collapse a node by UID
  static void collapseNode(String uid) {
    _DatabaseSourceBarState.collapseNode(uid);
  }
}

class _DatabaseSourceBarState extends State<DatabaseSourceBar> {
  //final OVApi _api = OVApi();
  DatabaseApi? _dbApi;
  //late final DatabaseSourceManager _manager;
  final Set<String> _expanded = <String>{};

  // Static reference to the current instance for direct access
  static _DatabaseSourceBarState? _currentInstance;

  @override
  void initState() {
    super.initState();
    _dbApi = OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    // Register this instance as the current one
    _currentInstance = this;
  }

  @override
  void didUpdateWidget(covariant DatabaseSourceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only override local selection if parent provides a non-null selection
    /*if (widget.selectedSource != null && widget.selectedSource != _selected) {
      _selected = widget.selectedSource;
    }*/
  }

  /*void _onManagerChanged() {
    if (mounted) setState(() {});
  }*/

  @override
  void dispose() {
    // Clear the static reference if this is the current instance
    if (_currentInstance == this) {
      _currentInstance = null;
    }
    super.dispose();
  }

  /// Static method to expand a node by UID
  static void expandNode(String uid, {bool expandChildren = false}) {
    _currentInstance?.setState(() {
      _currentInstance!._expanded.add(uid);
      if (expandChildren) {
        // Expand immediate children
        final sourceController = _currentInstance!._dbApi?.sourceController;
        if (sourceController == null) return;
        final source = sourceController.sources.allSources
            .where((s) => s.uid == uid)
            .firstOrNull;
        if (source != null) {
          for (final child in source.subSources) {
            expandNode(child.uid, expandChildren: true);
          }
        }
      }
    });
  }

  /// Static method to collapse a node by UID
  static void collapseNode(String uid) {
    _currentInstance?.setState(() {
      _currentInstance!._expanded.remove(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbTheme = context.databaseTheme;
    return Container(
      color: dbTheme.panelBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildSourcesTree()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final scheme = Theme.of(context).colorScheme;
    final dbTheme = context.databaseTheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: dbTheme.panelBg,
        border: Border(
          bottom: BorderSide(
            color: dbTheme.panelBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: scheme.onSurface,
            size: 20,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Expanded(
            child: Text(
              'Sources',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: null, //widget.onRefreshSources,
            icon: Icon(
              Icons.refresh,
              color: scheme.onSurfaceVariant,
              size: 18,
            ),
            tooltip: 'Refresh sources',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: null, //widget.onAddSource,
            icon: Icon(
              Icons.add,
              color: scheme.onSurfaceVariant,
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
    final scheme = Theme.of(context).colorScheme;
    final sourceController = _dbApi?.sourceController;
    final roots =
        sourceController == null ? [] : sourceController.sources.rootSources;
    if (roots.isEmpty) {
      return Center(
        child: Text(
          'No sources',
          style: TextStyle(color: scheme.onSurfaceVariant),
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
    final scheme = Theme.of(context).colorScheme;
    final dbTheme = context.databaseTheme;
    final isSelected = _dbApi?.sourceController.selectedSource == source;
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
                        ? dbTheme.sourceSelectedText
                        : scheme.onSurfaceVariant,
                  ),
                )
              : const SizedBox(width: 18),
          title: Text(
            source.name,
            style: TextStyle(
              color: isSelected
                  ? dbTheme.sourceSelectedText
                  : scheme.onSurface,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          selected: isSelected,
          selectedTileColor: dbTheme.sourceSelectedBg,
          onTap: () {
            _dbApi?.sourceController.selectSourceByUid(source.uid);

            /*setState(() {
              _selected = source;
            });
            widget.onSourceSelected?.call(source);*/
          },
        ),
        if (hasChildren && isExpanded)
          for (final child in source.subSources)
            _buildSourceNode(child, depth: depth + 1),
      ],
    );
  }

  Widget _buildFooter() {
    final scheme = Theme.of(context).colorScheme;
    final dbTheme = context.databaseTheme;
    final sourceController = _dbApi?.sourceController;
    final total = sourceController == null
        ? 0
        : sourceController.sources.allSources.length;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: dbTheme.panelBg,
        border: Border(
          top: BorderSide(
            color: dbTheme.panelBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: scheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Text(
            '$total sources',
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
