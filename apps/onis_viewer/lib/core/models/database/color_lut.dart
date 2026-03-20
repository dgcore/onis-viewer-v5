import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:onis_viewer/core/models/database/item.dart';
import 'package:onis_viewer/core/models/database/preference_item.dart';

class ColorLutPoint {
  int index = 0;
  List<int> rgb = [0, 0, 0];
  ColorLutPoint({required this.index, required this.rgb});

  ColorLutPoint clone() {
    return ColorLutPoint(index: index, rgb: rgb.toList());
  }
}

class ColorLut extends PreferenceItem {
  final List<Uint8List> _table = [];
  List<ColorLutPoint> _points = [];

  ColorLut? createFromData(dynamic data) {
    ColorLut item = ColorLut();
    if (!item.decodeData(data)) {
      return null;
    }
    return item;
  }

  ColorLut() : super('CL', '1.0.0.0') {
    _table.add(Uint8List(256));
    _table.add(Uint8List(256));
    _table.add(Uint8List(256));
    _init();
  }

  @override
  Item? clone(bool children) {
    ColorLut copy = ColorLut();
    copy.id = id;
    copy.flags = flags;
    copy.version = version;
    copyTo(copy, Item.kMerge);
    return copy;
  }

  int getBits() => 8;
  Uint8List? getEntries(int channel) {
    return _table[channel];
  }

  void recalculate() {
    if (_points.length < 2) return;
    int it1 = 0;
    int it2 = 0;
    it1 = 0;
    it2 = it1;
    it2++;
    while (it2 != _points.length) {
      int posFrom = max(0, _points[it1].index);
      posFrom = min(255, posFrom);
      int posTo = max(0, _points[it2].index);
      posTo = min(255, posTo);
      Uint8List colorFrom = Uint8List(3);
      Uint8List colorTo = Uint8List(3);
      for (int i = 0; i < 3; i++) {
        colorFrom[i] = _points[it1].rgb[i];
        colorTo[i] = _points[it2].rgb[i];
      }
      if (posFrom == posTo) {
        _table[0][posFrom] = colorFrom[0];
        _table[1][posFrom] = colorFrom[1];
        _table[2][posFrom] = colorFrom[2];
      } else {
        double finv = 1.0 / (posTo - posFrom);
        for (int i = posFrom; i <= posTo; i++) {
          for (int j = 0; j < 3; j++) {
            double fval = (i - posFrom) * (colorTo[j] - colorFrom[j]) * finv +
                colorFrom[j];
            double fres = fval - fval.floorToDouble();
            int ires = fval.round();
            if (fres > 0.5) ires++;
            ires = max(0, ires);
            ires = min(255, ires);
            _table[j][i] = ires;
          }
        }
      }
      it1 = it2;
      it2++;
    }
  }

  void setPoint(int index, int red, int green, int blue, bool recalc) {
    for (int it1 = 0; it1 < _points.length; it1++) {
      if (_points[it1].index == index) {
        _points[it1].rgb[0] = red;
        _points[it1].rgb[1] = green;
        _points[it1].rgb[2] = blue;
        if (recalc) recalculate();
        break;
      } else if (index < _points[it1].index) {
        ColorLutPoint newPoint =
            ColorLutPoint(index: index, rgb: [red, green, blue]);
        _points.insert(it1, newPoint);
        if (recalc) recalculate();
        break;
      }
    }
  }

  bool movePoint(int index, int newIndex, bool recalc) {
    if (newIndex < 0 || newIndex > 255) return false;
    if (index != newIndex) {
      for (int it1 = 0; it1 < _points.length; it1++) {
        if (_points[it1].index == newIndex) {
          return false;
        }
      }
    }
    for (int it1 = 0; it1 < _points.length; it1++) {
      if (_points[it1].index == index) {
        int red = 0, green = 0, blue = 0;
        red = _points[it1].rgb[0];
        green = _points[it1].rgb[1];
        blue = _points[it1].rgb[2];
        removePoint(index, false);
        setPoint(newIndex, red, green, blue, recalc);
        return true;
      }
    }
    return false;
  }

  void removePoint(int index, bool recalc) {
    if (index == 0) return;
    if (index == 255) return;
    for (int it1 = 0; it1 < _points.length; it1++) {
      if (_points[it1].index == index) {
        _points.removeAt(it1);
        if (recalc) recalculate();
        break;
      }
    }
  }

  int get pointCount => _points.length;

  List<int> getPoint(int index) {
    if (index >= 0 && index < _points.length) {
      return [
        _points[index].index,
        _points[index].rgb[0],
        _points[index].rgb[1],
        _points[index].rgb[2]
      ];
    }
    return [-1, -1, -1, -1];
  }

  int havePoint(int index) {
    for (int i = 0; i < _points.length; i++) {
      if (_points[i].index == index) return i;
    }
    return -1;
  }

  void _init() {
    ColorLutPoint pt = ColorLutPoint(index: 0, rgb: [0, 0, 0]);
    _points.add(pt);
    pt = ColorLutPoint(index: 255, rgb: [255, 255, 255]);
    _points.add(pt);
  }

  @override
  bool copyTo(Item target, int mode) {
    if (!super.copyTo(target, mode)) return false;
    if (hasFlag(PreferenceItem.infoPrefItemData)) {
      ColorLut to = target as ColorLut;
      if (to._points.isNotEmpty) to._points.clear();
      if (_points.isNotEmpty) {
        to._points = List.generate(
            _points.length,
            (i) => ColorLutPoint(
                index: _points[i].index, rgb: _points[i].rgb.toList()));
        to.recalculate();
      }
    }
    return true;
  }

  @override
  int compare(Item item) {
    int flags = super.compare(item);
    ColorLut other = item as ColorLut;
    if (hasFlag(PreferenceItem.infoPrefItemData) &&
        other.hasFlag(PreferenceItem.infoPrefItemData)) {
      if (_points.length != other._points.length) {
        flags |= PreferenceItem.infoPrefItemData;
      } else {
        for (int i = 0; i < _points.length; i++) {
          if (_points[i].index != other._points[i].index ||
              _points[i].rgb[0] != other._points[i].rgb[0] ||
              _points[i].rgb[1] != other._points[i].rgb[1] ||
              _points[i].rgb[2] != other._points[i].rgb[2]) {
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
      data.add({'i': _points[i].index, 'rgb': _points[i].rgb.toList()});
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
            setPoint(data[i].i, data[i].rgb[0], data[i].rgb[1], data[i].rgb[2],
                false);
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
