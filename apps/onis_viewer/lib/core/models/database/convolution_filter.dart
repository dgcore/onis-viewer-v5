import 'dart:convert';
import 'dart:math';

import 'package:onis_viewer/core/models/database/item.dart';
import 'package:onis_viewer/core/models/database/preference_item.dart';

class ConvolutionFilter extends PreferenceItem {
  List<double> _matrix = [];
  double _normalization = 1.0;

  static ConvolutionFilter? createFromData(dynamic data) {
    ConvolutionFilter item = ConvolutionFilter();
    if (!item.decode(data)) {
      return null;
    }
    return item;
  }

  ConvolutionFilter() : super('CF', '1.0.0.0') {
    _matrix = List.filled(9, 0.0);
    _matrix[4] = 1.0;
  }

  @override
  Item? clone(bool children) {
    ConvolutionFilter copy = ConvolutionFilter();
    copy.id = id;
    copy.flags = flags;
    copy.version = version;
    copyTo(copy, Item.kMerge);
    return copy;
  }

  int get dimension => sqrt(_matrix.length).toInt();
  get matrix => _matrix;
  get normalization => _normalization;

  bool setMatrix(List<double> matrix, double normalization) {
    if (dimension != 3 && dimension != 5) return false;
    _matrix = List.from(matrix);
    _normalization = normalization;
    return true;
  }

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    ConvolutionFilter to = target as ConvolutionFilter;
    if (hasFlag(PreferenceItem.infoPrefItemData)) {
      to._normalization = _normalization;
      to._matrix = List.from(_matrix);
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    ConvolutionFilter other = item as ConvolutionFilter;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (normalization != other.normalization) {
        flags |= PreferenceItem.infoPrefItemData;
      } else if (matrix.length != other.matrix.length) {
        flags |= PreferenceItem.infoPrefItemData;
      } else {
        for (int i = 0; i < matrix.length; i++) {
          if (matrix[i] != other.matrix[i]) {
            flags |= PreferenceItem.infoPrefItemData;
            break;
          }
        }
      }
    }
    return flags;
  }

  @override
  String encodeData() {
    Map<String, dynamic> data = {};
    data['n'] = _normalization;
    data['m'] = List<double>.from(_matrix);
    return jsonEncode(data);
  }

  @override
  bool decodeData(dynamic data) {
    try {
      if (data['n'] is double && data['m'] is List<double>) {
        _normalization = data['n'];
        _matrix = List<double>.from(data['m']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
