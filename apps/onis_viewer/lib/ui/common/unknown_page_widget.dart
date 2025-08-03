import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_type.dart';

/// Widget displayed when a page type is not supported
class UnknownPageWidget extends StatelessWidget {
  final PageType pageType;

  const UnknownPageWidget({
    super.key,
    required this.pageType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: OnisViewerConstants.textSecondaryColor,
            ),
            const SizedBox(height: OnisViewerConstants.marginMedium),
            Text(
              'Unknown Page Type',
              style: const TextStyle(
                color: OnisViewerConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: OnisViewerConstants.marginSmall),
            Text(
              'The page type "${pageType.name}" is not supported.',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OnisViewerConstants.marginSmall),
            Text(
              'ID: ${pageType.id}',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
