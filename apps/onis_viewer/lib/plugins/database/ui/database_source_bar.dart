import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/database_source.dart';
import '../page/database_controller.dart';

/// Database source bar that displays database sources in a hierarchical structure
class DatabaseSourceBar extends StatelessWidget {
  final DatabaseController controller;
  final DatabaseSource? selectedSource;
  final ValueChanged<DatabaseSource>? onSourceSelected;
  final VoidCallback? onAddSource;
  final VoidCallback? onRefreshSources;

  const DatabaseSourceBar({
    super.key,
    required this.controller,
    this.selectedSource,
    this.onSourceSelected,
    this.onAddSource,
    this.onRefreshSources,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Search bar
        _buildSearchBar(),

        // Sources tree
        Expanded(
          child: _buildSourcesTree(),
        ),

        // Footer actions
        _buildFooter(),
      ],
    );
  }

  /// Build the header section
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
            onPressed: onRefreshSources,
            icon: const Icon(
              Icons.refresh,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Refresh sources',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          IconButton(
            onPressed: onAddSource,
            icon: const Icon(
              Icons.add,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Add source',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search sources...',
          hintStyle: const TextStyle(
            color: OnisViewerConstants.textSecondaryColor,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: OnisViewerConstants.textSecondaryColor,
            size: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: OnisViewerConstants.tabButtonColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: OnisViewerConstants.tabButtonColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: OnisViewerConstants.primaryColor,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: OnisViewerConstants.paddingMedium,
            vertical: OnisViewerConstants.paddingSmall,
          ),
        ),
        style: const TextStyle(
          color: OnisViewerConstants.textColor,
          fontSize: 14,
        ),
        onChanged: (value) {
          // TODO: Implement search functionality
        },
      ),
    );
  }

  /// Build the sources tree
  Widget _buildSourcesTree() {
    // TODO: Replace with actual DatabaseSourceManager data
    // For now, using mock data
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: controller.databases.length,
      itemBuilder: (context, index) {
        final database = controller.databases[index];
        return _buildSourceItem(database, 0);
      },
    );
  }

  /// Build a source item
  Widget _buildSourceItem(dynamic source, int depth) {
    final isSelected = selectedSource?.uid == source.id;
    final hasChildren =
        source is Database && source.type == 'DICOM'; // Mock logic

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.only(
            left: OnisViewerConstants.paddingMedium + (depth * 20),
            right: OnisViewerConstants.paddingMedium,
          ),
          leading: Icon(
            _getSourceIcon(source),
            color: isSelected
                ? OnisViewerConstants.primaryColor
                : OnisViewerConstants.textSecondaryColor,
            size: 20,
          ),
          title: Text(
            source.name,
            style: TextStyle(
              color: isSelected
                  ? OnisViewerConstants.primaryColor
                  : OnisViewerConstants.textColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          subtitle: source is Database
              ? Text(
                  source.type,
                  style: const TextStyle(
                    color: OnisViewerConstants.textSecondaryColor,
                    fontSize: 12,
                  ),
                )
              : null,
          selected: isSelected,
          onTap: () {
            if (source is Database) {
              controller.selectDatabase(source);
            }
            // TODO: Handle DatabaseSource selection
          },
        ),

        // Show children if expanded (mock implementation)
        if (hasChildren && isSelected)
          ...List.generate(
              2,
              (index) => _buildSourceItem(
                    _MockSubSource('Sub-source ${index + 1}'),
                    depth + 1,
                  )),
      ],
    );
  }

  /// Get the appropriate icon for a source
  IconData _getSourceIcon(dynamic source) {
    if (source is Database) {
      switch (source.type) {
        case 'DICOM':
          return Icons.medical_services;
        case 'SQLite':
          return Icons.storage;
        case 'PostgreSQL':
          return Icons.dns;
        default:
          return Icons.folder;
      }
    }
    return Icons.folder;
  }

  /// Build the footer section
  Widget _buildFooter() {
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
            '${controller.databases.length} sources',
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

/// Mock class for sub-sources (temporary)
class _MockSubSource {
  final String name;
  _MockSubSource(this.name);
}
