import 'dart:convert';

import 'package:onis_viewer/core/models/database/item.dart';
import 'package:onis_viewer/core/models/database/preference_item.dart';

class WindowLevel extends PreferenceItem {
  double center = 128;
  double width = 256;

  WindowLevel? createFromData(dynamic data) {
    WindowLevel item = WindowLevel();
    if (!item.decodeData(data)) {
      return null;
    }
    return item;
  }

  WindowLevel() : super('WL', '1.0.0.0');

  @override
  Item? clone(bool children) {
    WindowLevel copy = WindowLevel();
    copy.id = id;
    copy.flags = flags;
    copy.version = version;
    copyTo(copy, Item.kMerge);
    return copy;
  }

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    if (hasFlag(PreferenceItem.infoPrefItemData)) {
      WindowLevel to = target as WindowLevel;
      to.center = center;
      to.width = width;
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    WindowLevel other = item as WindowLevel;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (center != other.center || width != other.width) {
        flags |= PreferenceItem.infoPrefItemData;
      }
    }
    return flags;
  }

  @override
  String encodeData() {
    Map<String, dynamic> data = {'c': center, 'w': width};
    return jsonEncode(data);
  }

  @override
  bool decodeData(dynamic data) {
    try {
      center = data.c;
      width = data.w;
      return true;
    } catch (e) {
      return false;
    }
  }
}
