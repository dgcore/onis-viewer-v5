import 'dart:convert';

import 'package:onis_viewer/core/models/database/item.dart';

class PreferenceItem extends Item {
  // Flag constants
  static const int infoPrefItemName = 1;
  static const int infoPrefItemStatus = 2;
  static const int infoPrefItemDescription = 4;
  static const int infoPrefItemShortcut = 8;
  static const int infoPrefItemData = 16;

  // JSON keys
  static const String pfiTypeKey = 'ptype';
  static const String pfiVersionKey = 'pversion';
  static const String pfiNameKey = 'name';
  static const String pfiDescKey = 'desc';
  static const String pfiStatusKey = 'status';
  static const String pfiShortcutKey = 'shortcut';
  static const String pfiDataKey = 'data';

  // Members
  String ptype = '';
  String pversion = '';
  String name = '';
  int status = 1;
  String description = '';
  int shortcutKey = 0;
  int shortcutModifier = 0;

  PreferenceItem(this.ptype, this.pversion);

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    PreferenceItem to = target as PreferenceItem;
    int flags = 0;
    List<int> tab = [
      infoPrefItemName,
      infoPrefItemStatus,
      infoPrefItemDescription,
      infoPrefItemShortcut,
      infoPrefItemData
    ];

    for (int flag in tab) {
      if (hasFlag(flag)) {
        if (mode == Item.kClone || mode == Item.kMerge) {
          to.flags |= flag;
          flags |= flag;
        } else if (mode == Item.kInter) {
          if (to.hasFlag(flag)) {
            flags |= flag;
          }
        }
      }
    }
    if (mode == Item.kClone) to.flags = flags;
    if (hasFlag(infoPrefItemName)) {
      to.name = name;
    }
    if (hasFlag(infoPrefItemStatus)) {
      to.status = status;
    }
    if (hasFlag(infoPrefItemDescription)) {
      to.description = description;
    }
    if (hasFlag(infoPrefItemShortcut)) {
      to.shortcutKey = shortcutKey;
      to.shortcutModifier = shortcutModifier;
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = 0;
    PreferenceItem other = item as PreferenceItem;
    if (pversion != other.pversion) return 0;
    if (hasFlag(infoPrefItemName) && other.hasFlag(infoPrefItemName)) {
      if (name != other.name) {
        flags |= PreferenceItem.infoPrefItemName;
      }
    }
    if (hasFlag(infoPrefItemStatus) && other.hasFlag(infoPrefItemStatus)) {
      if (status != other.status) {
        flags |= PreferenceItem.infoPrefItemStatus;
      }
    }
    if (hasFlag(infoPrefItemDescription) &&
        other.hasFlag(infoPrefItemDescription)) {
      if (description != other.description) {
        flags |= PreferenceItem.infoPrefItemDescription;
      }
    }
    if (hasFlag(infoPrefItemShortcut) && other.hasFlag(infoPrefItemShortcut)) {
      if (shortcutKey != other.shortcutKey) {
        flags |= PreferenceItem.infoPrefItemShortcut;
      } else if (shortcutModifier != other.shortcutModifier) {
        flags |= PreferenceItem.infoPrefItemShortcut;
      }
    }
    return flags;
  }

  @override
  void toJson(Map<String, dynamic> json) {
    super.toJson(json);
    json[PreferenceItem.pfiTypeKey] = ptype;
    json[PreferenceItem.pfiVersionKey] = pversion;
    if (hasFlag(PreferenceItem.infoPrefItemName)) {
      json[PreferenceItem.pfiNameKey] = name;
    }
    if (hasFlag(PreferenceItem.infoPrefItemDescription)) {
      json[PreferenceItem.pfiDescKey] = description;
    }
    if (hasFlag(PreferenceItem.infoPrefItemStatus)) {
      json[PreferenceItem.pfiStatusKey] = status;
    }
    if (hasFlag(PreferenceItem.infoPrefItemShortcut)) {
      json[PreferenceItem.pfiShortcutKey] = [shortcutKey, shortcutModifier];
    }
    if (hasFlag(PreferenceItem.infoPrefItemData)) {
      json[PreferenceItem.pfiDataKey] = encodeData();
    }
  }

  String encodeData() {
    return '{}';
  }

  bool decodeData(dynamic data) {
    return false;
  }

  bool decode(dynamic data) {
    try {
      id = data['id'];
      version = data['version'];
      flags = data['flags'];
      if ((flags & PreferenceItem.infoPrefItemName) != 0) {
        name = data[PreferenceItem.pfiNameKey];
      }
      if ((flags & PreferenceItem.infoPrefItemDescription) != 0) {
        description = data[PreferenceItem.pfiDescKey];
      }
      if ((flags & PreferenceItem.infoPrefItemStatus) != 0) {
        status = data[PreferenceItem.pfiStatusKey];
      }
      if ((flags & PreferenceItem.infoPrefItemShortcut) != 0) {
        shortcutKey = data[PreferenceItem.pfiShortcutKey][0];
        shortcutModifier = data[PreferenceItem.pfiShortcutKey][1];
      }
      if ((flags & PreferenceItem.infoPrefItemData) != 0) {
        final param = jsonDecode(data[PreferenceItem.pfiDataKey]);
        if (!decodeData(param)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

class UnknownPreferenceItem extends PreferenceItem {
  String data = '';

  UnknownPreferenceItem(super.type, super.version);

  @override
  Item? clone(bool children) {
    UnknownPreferenceItem copy = UnknownPreferenceItem(ptype, pversion);
    copy.flags = flags;
    copyTo(copy, Item.kInter);
    return copy;
  }

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    UnknownPreferenceItem to = target as UnknownPreferenceItem;
    if (target.hasFlag(PreferenceItem.infoPrefItemData)) to.data = data;
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    UnknownPreferenceItem other = item as UnknownPreferenceItem;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (data != other.data) flags |= PreferenceItem.infoPrefItemData;
    }
    return flags;
  }

  @override
  bool haveSameProperties(Item item) {
    if (!super.haveSameProperties(item)) return false;
    return compare(item) == 0;
  }
}
