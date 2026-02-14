import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// History bar widget for the viewer page
/// Fixed width, displayed on the left side, uses remaining height
class ViewerHistoryBar extends StatelessWidget {
  final double width;
  final List<String> historyItems;

  const ViewerHistoryBar({
    super.key,
    this.width = 250.0,
    this.historyItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        border: Border(
          right: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
            decoration: BoxDecoration(
              color: OnisViewerConstants.tabBarColor,
              border: Border(
                bottom: BorderSide(
                  color: OnisViewerConstants.tabButtonColor,
                  width: 1.0,
                ),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.history,
                  size: 20,
                  color: OnisViewerConstants.textColor,
                ),
                SizedBox(width: OnisViewerConstants.marginMedium),
                Text(
                  'History',
                  style: TextStyle(
                    color: OnisViewerConstants.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: historyItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 48,
                          color: OnisViewerConstants.textSecondaryColor,
                        ),
                        const SizedBox(
                            height: OnisViewerConstants.marginMedium),
                        Text(
                          'No history',
                          style: TextStyle(
                            color: OnisViewerConstants.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: historyItems.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: OnisViewerConstants.paddingMedium,
                          vertical: OnisViewerConstants.paddingSmall,
                        ),
                        leading: const Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: OnisViewerConstants.textSecondaryColor,
                        ),
                        title: Text(
                          historyItems[index],
                          style: const TextStyle(
                            color: OnisViewerConstants.textColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Handle history item selection
                          debugPrint('Selected history item: ${historyItems[index]}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

