import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/plugins/database/public/source_controller_interface.dart';
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
          onImport: () {
            // Use the state's context instead of the AnimatedBuilder context
            if (mounted) {
              _handleImport(this.context);
            }
          },
          onExport: () => {},
          onTransfer: () => {},
          onOpen: () {
            if (selected != null && mounted) {
              sourceController.openSelectedStudies(selected.uid, this.context);
            }
          },
          selectedLocation: 'Local computer',
          onSearch: () async {
            if (selected != null) {
              final response = await sourceController.findStudies(selected.uid);
              sourceController.setStudies(response);
            }
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
        : (loginPanel ?? _buildDatabaseDetails(sourceController!, selected));

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
  Widget _buildDatabaseDetails(
      ISourceController sourceController, DatabaseSource selectedSource) {
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

    final patientStudies =
        sourceController.getStudiesForSource(selectedSource.uid);
    final selectedStudies =
        sourceController.getSelectedStudiesForSource(selectedSource.uid);
    final username = 'madric';
    final isDisconnecting = false;

    return StudyListView(
      studies: patientStudies,
      selectedStudies: selectedStudies,
      onStudySelectionChanged: () => sourceController.notifyUpdate(),
      //onStudySelected: (study) {
      /*if (selected != null) {
          _controller.selectStudy(selected.uid, study);
        }*/
      //},
      //onStudiesSelected: (studies) {
      /*if (selected != null) {
          _controller.selectStudies(selected.uid, studies);
        }*/
      //},
      username: username,
      isDisconnecting: isDisconnecting,
      onDisconnect: () {
        selectedSource.disconnect();
      },
      initialScrollPositions:
          sourceController.getScrollPositionsForSource(selectedSource.uid),
      onScrollPositionChanged: (position) {
        debugPrint(
            'Database page received scroll position: horizontal=${position.horizontal}, vertical=${position.vertical} for source: ${selectedSource.uid}');
        final selected = sourceController.selectedSource;
        if (selected != null) {
          sourceController.saveScrollPositionsForSource(
              selected.uid, position.horizontal, position.vertical);
        }
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
    String message = 'Database:${_buildSourcePath(selected)}';
    final statuses = sourceController!.getSourceStatuses(selected.uid);
    if (statuses.isNotEmpty) {
      for (final status in statuses) {
        if (status.status != OnisErrorCodes.none) {
          message +=
              ' -  ${status.sourceUid}: ${OnisErrorCodes.getErrorMessage(status.status)}';
        }
      }
    }
    return message;
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

  /// Handle import button click - show file/folder picker
  Future<void> _handleImport(BuildContext context) async {
    if (!mounted || !context.mounted) {
      debugPrint('Context not mounted in _handleImport');
      return;
    }

    try {
      debugPrint('Opening import dialog...');
      // Show dialog to choose between files or folders
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Import'),
            content: const Text('What would you like to import?'),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('User selected: files');
                  Navigator.of(dialogContext).pop('files');
                },
                child: const Text('Files'),
              ),
              TextButton(
                onPressed: () {
                  debugPrint('User selected: folder');
                  Navigator.of(dialogContext).pop('folder');
                },
                child: const Text('Folder'),
              ),
              TextButton(
                onPressed: () {
                  debugPrint('User cancelled dialog');
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );

      debugPrint('Dialog returned: $choice');
      if (choice == null || !mounted || !context.mounted) {
        debugPrint('No choice or context not mounted');
        return;
      }

      if (choice == 'files') {
        // Pick files
        try {
          final result = await FilePicker.platform.pickFiles(
            allowMultiple: true,
            type: FileType.any,
            dialogTitle: 'Select files to import',
          );
          if (!mounted || !context.mounted) return;

          if (result != null && result.files.isNotEmpty) {
            final filePaths = result.files
                .map((file) => file.path ?? '')
                .where((path) => path.isNotEmpty)
                .toList();
            if (filePaths.isNotEmpty) {
              debugPrint('Selected files: $filePaths');
              // TODO: Handle selected files
              // Use the showMessage method from BasePageState which handles Scaffold properly
              showMessage(
                  'Selected ${filePaths.length} file(s):\n${filePaths.take(3).join('\n')}${filePaths.length > 3 ? '\n...' : ''}');

              final sourceController = _dbApi?.sourceController;
              final selected = sourceController?.selectedSource;
              if (selected != null) {
                for (final filePath in filePaths) {
                  final response = await sourceController!
                      .importDicomFile(selected.uid, filePath);
                  if (response != null) {
                    debugPrint('Import response: $response');
                  }
                }
              }
            }
          }
        } catch (e, stackTrace) {
          debugPrint('Error in file picker: $e');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) {
            showMessage('Error opening file picker: $e', isError: true);
          }
        }
      } else if (choice == 'folder') {
        // Pick folder
        debugPrint('Opening directory picker...');
        try {
          // On macOS, we need to wait for the dialog to fully close before opening the file picker
          // This ensures the system is ready to show the file picker dialog
          //await Future.delayed(const Duration(milliseconds: 300));

          if (!mounted || !context.mounted) {
            debugPrint('Context not mounted before opening directory picker');
            return;
          }

          debugPrint('Calling getDirectoryPath...');
          String? selectedDirectory =
              await FilePicker.platform.getDirectoryPath(
            dialogTitle: 'Select folder to import',
          );

          debugPrint('Directory picker result: $selectedDirectory');

          if (!mounted || !context.mounted) return;

          if (selectedDirectory != null && selectedDirectory.isNotEmpty) {
            debugPrint('Selected directory: $selectedDirectory');
            // TODO: Handle selected folder
            showMessage('Selected folder: $selectedDirectory');
          } else {
            debugPrint(
                'Directory picker was cancelled by user or returned null/empty');
            // This is normal if user cancels - don't show error
          }
        } catch (e, stackTrace) {
          debugPrint('Error in directory picker: $e');
          debugPrint('Stack trace: $stackTrace');
          if (mounted) {
            showMessage('Error opening folder picker: $e', isError: true);
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error in _handleImport: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        showMessage('Error: $e', isError: true);
      }
    }
  }
}
