import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:onis_viewer/core/models/database/item.dart';
import 'package:onis_viewer/core/models/database/preference_item.dart';

class OpacityTablePoint {
  int index = 0;
  double value = 0.0;
  OpacityTablePoint({required this.index, required this.value});
}

class OpacityTable extends PreferenceItem {
  Uint8List? _table;
  List<OpacityTablePoint> _points = [];

  OpacityTable? createFromData(dynamic data) {
    OpacityTable item = OpacityTable();
    if (!item.decodeData(data)) {
      return null;
    }
    return item;
  }

  OpacityTable() : super('OT', '1.0.0.0') {
    _table = Uint8List(256);
    _init();
  }

  @override
  Item? clone(bool children) {
    OpacityTable copy = OpacityTable();
    copy.id = id;
    copy.flags = flags;
    copy.version = version;
    copyTo(copy, Item.kMerge);
    return copy;
  }

  Uint8List? get table {
    if (_table == null) {
      recalculate();
    }
    return _table;
  }

  void recalculate() {
    if (_points.length < 2) return;
    _table ??= Uint8List(256);
    int it1, it2;
    it1 = 0;
    it2 = it1;
    it2++;
    while (it2 != _points.length) {
      int posFrom = max(0, _points[it1].index);
      posFrom = min(255, posFrom);
      int posTo = max(0, _points[it2].index);
      posTo = min(255, posTo);
      double valueFrom = _points[it1].value;
      double valueTo = _points[it2].value;
      if (posFrom == posTo) {
        double fres = valueFrom - valueFrom.floorToDouble();
        int ires = valueFrom.round();
        if (fres > 0.5) ires++;
        ires = max(0, ires);
        ires = min(255, ires);
        _table![posFrom] = ires;
      } else {
        double finv = 1.0 / (posTo - posFrom);
        for (int i = posFrom; i <= posTo; i++) {
          double fval =
              (i - posFrom) * (valueTo - valueFrom) * finv + valueFrom;
          fval *= 255.0;
          double fres = fval - fval.floorToDouble();
          int ires = fval.round();
          if (fres > 0.5) ires++;
          ires = max(0, ires);
          ires = min(255, ires);
          _table![i] = ires;
        }
      }
      it1 = it2;
      it2++;
    }
  }

  void setPoint(int index, double value, bool recalc) {
    for (int it1 = 0; it1 < _points.length; it1++) {
      if (_points[it1].index == index) {
        _points[it1].value = value;
        if (recalc) recalculate();
        break;
      } else if (index < _points[it1].index) {
        OpacityTablePoint newPoint =
            OpacityTablePoint(index: index, value: value);
        _points.insert(it1, newPoint);
        if (recalc) recalculate();
        break;
      }
    }
  }

  bool movePoint(int index, int newIndex, double newValue, bool recalc) {
    if (index != newIndex) {
      for (int it1 = 0; it1 < _points.length; it1++) {
        if (_points[it1].index == newIndex) {
          return false;
        }
      }
    }
    for (int it1 = 0; it1 < _points.length; it1++) {
      if (_points[it1].index == index) {
        if (index != newIndex) removePoint(index, false);
        setPoint(newIndex, newValue, recalc);
        return true;
      }
    }
    return false;
  }

  void removePoint(int index, bool recalc) {
    if (index == 0) return;
    if (index == 255) return;
    for (int it1 = 0; it1 <= _points.length; it1++) {
      if (_points[it1].index == index) {
        _points.removeAt(it1);
        if (recalc) recalculate();
        break;
      }
    }
  }

  get pointCount => _points.length;

  List<int> getPoint(int index) {
    if (index >= 0 && index < _points.length) {
      return [_points[index].index, _points[index].value.round()];
    }
    return [-1, -1];
  }

  int havePoint(int index) {
    for (int i = 0; i < _points.length; i++) {
      if (_points[i].index == index) return i;
    }
    return -1;
  }

  void _init() {
    _table = null;
    OpacityTablePoint pt = OpacityTablePoint(index: 0, value: 0.0);
    _points.add(pt);
    pt = OpacityTablePoint(index: 255, value: 1.0);
    _points.add(pt);
  }

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    if (hasFlag(PreferenceItem.infoPrefItemData)) {
      OpacityTable to = target as OpacityTable;
      if (to._points.isNotEmpty) to._points.clear();
      if (_points.isNotEmpty) {
        to._points = List.generate(
            _points.length,
            (i) => OpacityTablePoint(
                index: _points[i].index, value: _points[i].value));
        to.recalculate();
      }
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    OpacityTable other = item as OpacityTable;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (_points.length != other._points.length) {
        flags |= PreferenceItem.infoPrefItemData;
      } else {
        for (int i = 0; i < _points.length; i++) {
          if (_points[i].index != other._points[i].index ||
              _points[i].value != other._points[i].value) {
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
    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < _points.length; i++) {
      data.add({'i': _points[i].index, 'v': _points[i].value});
    }
    return jsonEncode(data);
  }

  @override
  bool decodeData(dynamic data) {
    try {
      if (data[0]['i'] is int && data[data.length - 1]['i'] is int) {
        if (data[0].i == 0 && data[data.length - 1].i == 255) {
          if (_points.length > 2) _points.removeRange(1, _points.length - 2);
          for (int i = 0; i < data.length; i++) {
            setPoint(data[i].i, data[i].v, false);
          }
          recalculate();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
