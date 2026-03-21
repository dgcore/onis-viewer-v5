import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/graphics/renderer/items/responder.dart';

class OsGraphicGroup extends OsGraphicResponder {
  OsGraphicGroup([String name = ''])
      : super(type: OsRenderItemType.osGroupItem, name: name);

  @override
  OsGraphicItem? clone() {
    OsGraphicGroup copy = OsGraphicGroup(getName());
    copy.copyProperties(this);
    return copy;
  }
}
