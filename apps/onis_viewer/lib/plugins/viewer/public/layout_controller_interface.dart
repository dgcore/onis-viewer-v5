import 'package:flutter/material.dart';

import '../core/layout/view_layout_node.dart';

/// Interface for LayoutController functionality
abstract class ILayoutController extends ChangeNotifier {
  /// Get the root node of the layout tree
  ViewLayoutNode get rootNode;
}
