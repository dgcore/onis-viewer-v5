import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../pages/base/base_page.dart';
import '../database_plugin.dart';
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
    return Column(
      children: [
        // Database toolbar
        _buildToolbar(),

        // Database content
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  /// Build the database toolbar
  Widget _buildToolbar() {
    return Container(
      height: 50,
      color: OnisViewerConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      child: Row(
        children: [
          // Add database button
          ElevatedButton.icon(
            onPressed: _controller.addDatabase,
            icon: const Icon(Icons.add),
            label: const Text('Add Database'),
          ),
          const SizedBox(width: OnisViewerConstants.marginMedium),

          // Refresh button
          ElevatedButton.icon(
            onPressed: _controller.refreshDatabases,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
          const SizedBox(width: OnisViewerConstants.marginMedium),

          // Search field
          Expanded(
            child: TextField(
              onChanged: _controller.searchDatabases,
              decoration: const InputDecoration(
                hintText: 'Search databases...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the main content area
  Widget _buildContent() {
    return Row(
      children: [
        // Database list (left panel)
        Container(
          width: 300,
          color: OnisViewerConstants.surfaceColor,
          child: _buildDatabaseList(),
        ),

        // Database details (right panel)
        Expanded(
          child: _buildDatabaseDetails(),
        ),
      ],
    );
  }

  /// Build the database list
  Widget _buildDatabaseList() {
    return Column(
      children: [
        // List header
        Container(
          height: 40,
          color: OnisViewerConstants.tabBarColor,
          padding: const EdgeInsets.symmetric(
            horizontal: OnisViewerConstants.paddingMedium,
          ),
          child: const Row(
            children: [
              Text(
                'Databases',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: OnisViewerConstants.textColor,
                ),
              ),
            ],
          ),
        ),

        // Database list
        Expanded(
          child: ListView.builder(
            itemCount: _controller.databases.length,
            itemBuilder: (context, index) {
              final database = _controller.databases[index];
              return ListTile(
                leading: const Icon(Icons.storage),
                title: Text(database.name),
                subtitle: Text(database.path),
                selected: _controller.selectedDatabase == database,
                onTap: () => _controller.selectDatabase(database),
              );
            },
          ),
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
