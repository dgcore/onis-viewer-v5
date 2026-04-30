import 'package:flutter/material.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';

import '../../../api/core/ov_api_core.dart';
import '../../../core/constants.dart';
import '../../../core/database_source.dart';
import '../../../core/theme/app_theme.dart';

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
    final appTheme = context.appTheme;
    return Container(
      color: appTheme.panelBg,
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
    final appTheme = context.appTheme;
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      decoration: BoxDecoration(
        color: appTheme.panelBg,
        border: Border(
          bottom: BorderSide(
            color: appTheme.panelBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            color: appTheme.textPrimary,
            size: 20,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Expanded(
            child: Text(
              'Sources',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: appTheme.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: null, //widget.onRefreshSources,
            icon: Icon(
              Icons.refresh,
              color: appTheme.textSecondary,
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
              color: appTheme.textSecondary,
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
    final appTheme = context.appTheme;
    final sourceController = _dbApi?.sourceController;
    final roots =
        sourceController == null ? [] : sourceController.sources.rootSources;
    if (roots.isEmpty) {
      return Center(
        child: Text(
          'No sources',
          style: TextStyle(color: appTheme.textSecondary),
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
    final appTheme = context.appTheme;
    final sourceController = _dbApi?.sourceController;
    final isSelected = _dbApi?.sourceController.selectedSource == source;
    final isExpanded = _expanded.contains(source.uid);
    final hasChildren = source.subSources.isNotEmpty;
    final showStatusDot = depth == 0;
    final studiesCount =
        sourceController?.getStudiesForSource(source.uid).length ?? 0;

    final Color statusColor;
    switch (source.loginState.status) {
      case ConnectionStatus.loggedIn:
        statusColor = const Color(0xFF2ECC71);
        break;
      case ConnectionStatus.loggingIn:
      case ConnectionStatus.disconnecting:
        statusColor = scheme.tertiary;
        break;
      case ConnectionStatus.disconnected:
        statusColor = scheme.onSurfaceVariant.withValues(alpha: 0.5);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            _dbApi?.sourceController.selectSourceByUid(source.uid);
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? appTheme.selectionBg : Colors.transparent,
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  color:
                      isSelected ? appTheme.selectionText : Colors.transparent,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 10 + (depth * 14),
                      right: OnisViewerConstants.paddingMedium,
                    ),
                    child: Row(
                      children: [
                        if (hasChildren)
                          IconButton(
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
                                  ? appTheme.selectionText
                                  : appTheme.textSecondary,
                            ),
                          )
                        else
                          const SizedBox(width: 18),
                        if (showStatusDot) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ] else
                          const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            source.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? appTheme.selectionText
                                  : appTheme.textPrimary,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (studiesCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: appTheme.textSecondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$studiesCount',
                              style: TextStyle(
                                color: appTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasChildren && isExpanded)
          for (final child in source.subSources)
            _buildSourceNode(child, depth: depth + 1),
      ],
    );
  }

  Widget _buildFooter() {
    final appTheme = context.appTheme;
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
        color: appTheme.panelBg,
        border: Border(
          top: BorderSide(
            color: appTheme.panelBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: appTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Text(
            '$total sources',
            style: TextStyle(
              color: appTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
