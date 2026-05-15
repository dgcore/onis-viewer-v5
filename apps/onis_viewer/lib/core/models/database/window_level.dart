import 'dart:convert';

import 'package:onis_viewer/core/models/database/item.dart';
import 'package:onis_viewer/core/models/database/preference_item.dart';

class WindowLevel {
  double center = 128;
  double width = 256;

  WindowLevel({this.center = 128, this.width = 256});

  WindowLevel clone() {
    return WindowLevel(
      center: center,
      width: width,
    );
  }
}

class WindowLevelPreset extends PreferenceItem {
  WindowLevel windowLevel = WindowLevel();

  WindowLevelPreset? createFromData(dynamic data) {
    WindowLevelPreset item = WindowLevelPreset();
    if (!item.decodeData(data)) {
      return null;
    }
    return item;
  }

  WindowLevelPreset() : super('WL', '1.0.0.0');

  @override
  Item? clone(bool children) {
    WindowLevelPreset copy = WindowLevelPreset();
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
      WindowLevelPreset to = target as WindowLevelPreset;
      to.windowLevel.center = windowLevel.center;
      to.windowLevel.width = windowLevel.width;
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    WindowLevelPreset other = item as WindowLevelPreset;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (windowLevel.center != other.windowLevel.center ||
          windowLevel.width != other.windowLevel.width) {
        flags |= PreferenceItem.infoPrefItemData;
      }
    }
    return flags;
  }

  @override
  String encodeData() {
    Map<String, dynamic> data = {
      'c': windowLevel.center,
      'w': windowLevel.width
    };
    return jsonEncode(data);
  }

  @override
  bool decodeData(dynamic data) {
    try {
      windowLevel.center = data.c;
      windowLevel.width = data.w;
      return true;
    } catch (e) {
      return false;
    }
  }
}
