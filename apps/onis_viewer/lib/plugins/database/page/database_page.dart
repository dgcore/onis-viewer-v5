import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants.dart';
import '../../../pages/base/base_page.dart';
import '../database_plugin.dart';
import '../ui/database_source_bar.dart';
import '../ui/database_toolbar.dart';
import '../ui/resizable_source_bar.dart';
import '../ui/study_list_view.dart';
import 'database_controller.dart';

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
  late DatabaseController _controller;
  bool _isCtrlPressed = false;
  bool _isShiftPressed = false;
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  Future<void> initializePage() async {
    _controller = DatabaseController();
    await _controller.initialize();
  }

  @override
  Future<void> disposePage() async {
    await _controller.dispose();
  }

  @override
  Widget buildPageContent() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                  event.logicalKey == LogicalKeyboardKey.controlRight ||
                  event.logicalKey == LogicalKeyboardKey.metaLeft ||
                  event.logicalKey == LogicalKeyboardKey.metaRight) {
                setState(() {
                  _isCtrlPressed = true;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                  event.logicalKey == LogicalKeyboardKey.shiftRight) {
                setState(() {
                  _isShiftPressed = true;
                });
              }
            } else if (event is KeyUpEvent) {
              if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                  event.logicalKey == LogicalKeyboardKey.controlRight ||
                  event.logicalKey == LogicalKeyboardKey.metaLeft ||
                  event.logicalKey == LogicalKeyboardKey.metaRight) {
                setState(() {
                  _isCtrlPressed = false;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                  event.logicalKey == LogicalKeyboardKey.shiftRight) {
                setState(() {
                  _isShiftPressed = false;
                });
              }
            }
            return KeyEventResult.handled;
          },
          child: _buildContent(),
        );
      },
    );
  }

  @override
  Widget? buildPageHeader() {
    // Return the database toolbar as the custom page header
    return DatabaseToolbar(
      onPreferences: () => _controller.openPreferences(),
      onImport: () => _controller.importData(),
      onExport: () => _controller.exportData(),
      onTransfer: () => _controller.transferData(),
      onOpen: () => _controller.openDatabaseFromToolbar(),
      selectedLocation: 'Local computer',
      onSearch: () => _controller.search(),
    );
  }

  /// Build the main content area
  Widget _buildContent() {
    return Row(
      children: [
        // Resizable source bar (left panel)
        ResizableSourceBar(
          initialWidth: 300,
          minWidth: 250,
          maxWidth: 500,
          child: DatabaseSourceBar(
            controller: _controller,
            selectedSource: null, // TODO: Add selected source tracking
            onSourceSelected: (source) {
              // TODO: Handle source selection
            },
            onAddSource: () {
              // TODO: Handle add source
            },
            onRefreshSources: () {
              // TODO: Handle refresh sources
            },
          ),
        ),

        // Spacing between source bar and study list
        const SizedBox(width: OnisViewerConstants.paddingMedium),

        // Database details (right panel)
        Expanded(
          child: _buildDatabaseDetails(),
        ),
      ],
    );
  }

  /// Build the database details panel
  Widget _buildDatabaseDetails() {
    // Always show the study list, but with different header based on selection
    return StudyListView(
      studies: _controller.studies,
      selectedStudies: _controller.selectedStudies,
      onStudySelected: (study) => _controller.selectStudy(study),
      onStudiesSelected: (studies) => _controller.selectStudies(studies),
      isCtrlPressed: _isCtrlPressed,
      isShiftPressed: _isShiftPressed,
      onRefreshStudies: () {
        // TODO: Implement refresh studies
        debugPrint('Refresh studies');
      },
      onAddStudy: () {
        // TODO: Implement add study
        debugPrint('Add study');
      },
    );
  }

  @override
  List<Widget> buildToolbarItems() {
    return [
      // Database-specific toolbar items
      IconButton(
        onPressed: _controller.showSettings,
        icon: const Icon(Icons.settings),
        tooltip: 'Database Settings',
      ),
    ];
  }

  @override
  List<Widget> buildFooterItems() {
    return [
      // Database-specific footer items
      Text(
        '${_controller.databases.length} databases',
        style: const TextStyle(
          fontSize: 12,
          color: OnisViewerConstants.textSecondaryColor,
        ),
      ),
    ];
  }

  @override
  String getPageStatus() {
    return 'Database: ${_controller.selectedDatabase?.name ?? 'None selected'}';
  }
}
