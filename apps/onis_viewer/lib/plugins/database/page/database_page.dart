import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/core/models/study.dart';
import 'package:onis_viewer/plugins/database/ui/study_list_view.dart';

import '../../../api/core/ov_api_core.dart';
import '../../../core/constants.dart';
import '../../../core/database_source.dart';
import '../../../pages/base/base_page.dart';
import '../database_plugin.dart';
import '../public/database_api.dart';
import '../ui/database_source_bar.dart';
import '../ui/database_toolbar.dart';
import '../ui/resizable_source_bar.dart';
//import 'database_controller.dart';

/// Database management page
class DatabasePage extends BasePage {
  const DatabasePage({
    super.key,
    super.parameters,
  }) : super(
          pageType: databasePageType,
        );

  @override
  BasePageState createPageState() => _DatabasePageState();
}

class _DatabasePageState extends BasePageState<DatabasePage> {
  //late DatabaseController _controller;
  DatabaseApi? _dbApi;
  //StreamSubscription<DatabaseSource?>? _selectionSub;
  //DatabaseSource? _selectedSource;
  //VoidCallback? _sourceListener;

  @override
  Future<void> initializePage() async {
    //_controller = DatabaseController();
    //await _controller.initialize();
    _dbApi = OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    //_selectionSub = _dbApi?.onSelectionChanged.listen((source) {
    //if (!mounted) return;
    // Remove listener from previous source
    //_selectedSource?.removeListener(_sourceListener!);
    //_selectedSource = source;
    // Add listener to new source
    //if (source != null) {
    //  _sourceListener = () {
    //    if (mounted) setState(() {});
    //  };
    //  source.addListener(_sourceListener!);
    // }
    // Defer setState to after the current build phase completes
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    // if (mounted) setState(() {});
    //});
    //});
  }

  @override
  Future<void> disposePage() async {
    if (_dbApi != null) {
      _dbApi!.sourceController.dispose();
    }

    //await _controller.dispose();
    //await _selectionSub?.cancel();
//    _selectedSource?.removeListener(_sourceListener!);
  }

  @override
  Widget buildPageContent() {
    final sourceController = _dbApi?.sourceController;
    return AnimatedBuilder(
      animation: sourceController as Listenable,
      builder: (context, child) {
        return _buildContent();
      },
    );
  }

  @override
  Widget? buildPageHeader() {
    // Return the database toolbar as the custom page header
    // Use AnimatedBuilder to rebuild when controller changes
    final sourceController = _dbApi?.sourceController;
    return AnimatedBuilder(
      animation: sourceController as Listenable,
      builder: (context, child) {
        // Get the selected source to determine capabilities
        final selected = sourceController!.selectedSource;
        final canOpen = sourceController.canOpen(selected?.uid ?? '');
        final canImport = sourceController.canImport(selected?.uid ?? '');
        final canExport = sourceController.canExport(selected?.uid ?? '');
        final canTransfer = sourceController.canTransfer(selected?.uid ?? '');
        final canSearch = sourceController.canSearch(selected?.uid ?? '');

        return DatabaseToolbar(
          onPreferences: () => {},
          onImport: () => {},
          onExport: () => {},
          onTransfer: () => {},
          onOpen: () => {},
          selectedLocation: 'Local computer',
          onSearch: () {
            /*final selected = _dbApi?.selectedSource;
            if (selected != null) {
              _controller.onSearch(selected.uid);
            }*/
          },
          canOpen: canOpen,
          canImport: canImport,
          canExport: canExport,
          canTransfer: canTransfer,
          canSearch: canSearch,
        );
      },
    );
  }

  /// Build the main content area
  Widget _buildContent() {
    final sourceController = _dbApi?.sourceController;
    final selected = sourceController?.selectedSource;
    Widget? loginPanel;
    if (selected != null) {
      if (selected.loginState.status != ConnectionStatus.loggedIn) {
        loginPanel = selected.buildLoginPanel(context, true);
      }
    }
    final rightPanel = selected == null
        ? _buildNoSelectionPlaceholder()
        : (loginPanel ?? _buildDatabaseDetails());

    return Row(
      children: [
        // Resizable source bar (left panel)
        ResizableSourceBar(
          initialWidth: 300,
          minWidth: 250,
          maxWidth: 500,
          child: DatabaseSourceBar(
              //selectedSource: selected,
              //onSourceSelected: (source) {
              //_dbApi?.selectSourceByUid(source.uid);
              //},
              //onAddSource: () {
              // TODO: Handle add source
              //},
              //onRefreshSources: () {
              // TODO: Handle refresh sources
              //},
              ),
        ),

        // Spacing between source bar and right panel
        const SizedBox(width: OnisViewerConstants.paddingMedium),

        // Right panel
        Expanded(child: rightPanel),
      ],
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.folder_open_outlined,
              size: 40, color: OnisViewerConstants.textSecondaryColor),
          SizedBox(height: 8),
          Text(
            'No source selected',
            style: TextStyle(
              color: OnisViewerConstants.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the database details panel
  Widget _buildDatabaseDetails() {
    // Always show the study list, but with different header based on selection
    /*final selected = _dbApi?.selectedSource;
    final username = selected?.currentUsername;
    final isDisconnecting = selected?.isDisconnecting ?? false;

    // Get studies for the current source
    final studies = selected != null
        ? _controller.getStudiesForSource(selected.uid)
        : <Study>[];
    final selectedStudies = selected != null
        ? _controller.getSelectedStudiesForSource(selected.uid)
        : <Study>[];*/

    final sourceController = _dbApi?.sourceController;
    final selectedSource = sourceController?.selectedSource;

    final studies = <Study>[];
    final selectedStudies = <Study>[];
    final username = 'madric';
    final isDisconnecting = false;

    return StudyListView(
      studies: studies,
      selectedStudies: selectedStudies,
      onStudySelected: (study) {
        /*if (selected != null) {
          _controller.selectStudy(selected.uid, study);
        }*/
      },
      onStudiesSelected: (studies) {
        /*if (selected != null) {
          _controller.selectStudies(selected.uid, studies);
        }*/
      },
      username: username,
      isDisconnecting: isDisconnecting,
      onDisconnect: () {
        if (selectedSource != null) {
          selectedSource.disconnect();
        }
      },
      initialScrollPosition: /*selected != null
          ? _controller.getScrollPositionForSource(selected.uid)
          :*/
          0.0,
      onScrollPositionChanged: (position) {
        /*debugPrint(
            'Database page received scroll position: $position for source: ${selected?.uid}');
        if (selected != null) {
          _controller.saveScrollPositionForSource(selected.uid, position);
        }*/
      },
    );
  }

  @override
  List<Widget> buildToolbarItems() {
    //final sourceController = _dbApi?.sourceController;
    return [
      // Database-specific toolbar items
      IconButton(
        onPressed: null, //_controller.showSettings,
        icon: const Icon(Icons.settings),
        tooltip: 'Database Settings',
      ),
    ];
  }

  @override
  List<Widget> buildFooterItems() {
    final sourceController = _dbApi?.sourceController;
    if (sourceController == null) {
      return [];
    }
    return [
      // Database-specific footer items
      Text(
        '${sourceController.totalStudyCount} studies',
        style: const TextStyle(
          fontSize: 12,
          color: OnisViewerConstants.textSecondaryColor,
        ),
      ),
    ];
  }

  @override
  String getPageStatus() {
    final sourceController = _dbApi?.sourceController;
    final selected = sourceController?.selectedSource;
    if (selected == null) {
      return 'Database: None selected';
    }
    final path = _buildSourcePath(selected);
    return 'Database: $path';
  }

  String _buildSourcePath(DatabaseSource source) {
    final segments = <String>[];
    DatabaseSource? current = source;
    while (current != null) {
      segments.insert(0, current.name);
      current = current.parent;
    }
    return segments.join(' > ');
  }
}
