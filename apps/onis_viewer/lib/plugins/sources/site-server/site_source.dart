import 'dart:core';

import '../../../core/database_source.dart';

class SiteSource extends DatabaseSource {
  /// Public constructor for a site source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  SiteSource({required super.uid, required super.name, super.metadata})
      : super();
}
