import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../pages/base/base_page.dart';
import '../database_plugin.dart';
import '../ui/database_source_bar.dart';
import '../ui/database_toolbar.dart';
import '../ui/resizable_source_bar.dart';
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
    return _buildContent();
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

        // Database details (right panel)
        Expanded(
          child: _buildDatabaseDetails(),
        ),
      ],
    );
  }

  /// Build the database details panel
  Widget _buildDatabaseDetails() {
    final selectedDb = _controller.selectedDatabase;

    if (selectedDb == null) {
      return const Center(
        child: Text(
          'Select a database to view details',
          style: TextStyle(
            color: OnisViewerConstants.textSecondaryColor,
            fontSize: 16,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Database header
          Text(
            selectedDb.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: OnisViewerConstants.textColor,
            ),
          ),
          const SizedBox(height: OnisViewerConstants.marginMedium),

          // Database info
          _buildInfoCard('Path', selectedDb.path),
          const SizedBox(height: OnisViewerConstants.marginSmall),
          _buildInfoCard('Type', selectedDb.type),
          const SizedBox(height: OnisViewerConstants.marginSmall),
          _buildInfoCard('Status', selectedDb.status),
          const SizedBox(height: OnisViewerConstants.marginSmall),
          _buildInfoCard('Size', selectedDb.size),

          const SizedBox(height: OnisViewerConstants.marginLarge),

          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _controller.openDatabase(selectedDb),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open'),
              ),
              const SizedBox(width: OnisViewerConstants.marginMedium),
              ElevatedButton.icon(
                onPressed: () => _controller.exportDatabase(selectedDb),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
              const SizedBox(width: OnisViewerConstants.marginMedium),
              ElevatedButton.icon(
                onPressed: () => _controller.deleteDatabase(selectedDb),
                icon: const Icon(Icons.delete),
                label: const Text('Delete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build an info card
  Widget _buildInfoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: OnisViewerConstants.tabButtonColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: OnisViewerConstants.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: OnisViewerConstants.textColor,
            ),
          ),
        ],
      ),
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
