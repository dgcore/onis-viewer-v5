import 'package:onis_viewer/core/graphics/drivers/driver.dart';
import 'package:onis_viewer/core/graphics/interfaces.dart';
import 'package:onis_viewer/core/graphics/math/matrix.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';

const int s32Max = 2147483647;

enum OsRenderItemType {
  osAnyItem,
  osCameraItem,
  osImageItem,
  osGroupItem,
  osAnnotationItem,
  osToolbarItem,
  osToolbarWidgetItem,
  osCustomItem,
}

///////////////////////////////////////////////////////////////////////
// item
///////////////////////////////////////////////////////////////////////

class OsGraphicItem {
  OsGraphicItem(
      [OsRenderItemType type = OsRenderItemType.osAnyItem, String name = '']) {
    _type = type;
    _name = name;
    _selectable = false;
    _selected = false;
  }

  bool active = true;
  bool visible = true;
  bool inherits = true;
  final List<double> pos = [0, 0, 0];
  final List<double> rot = [0, 0, 0];
  final List<double> sca = [1, 1, 1];
  final List<double> rotPiv = [0, 0, 0];
  final List<double> scaPiv = [0, 0, 0];
  final List<double> rotPivTrans = [0, 0, 0];
  final List<double> scaPivTrans = [0, 0, 0];
  final List<double> shear = [0, 0, 0];
  final List<double> rotAxe = [0, 0, 0];
  String userData = '';
  final OsMatrix localMatrix = OsMatrix();
  final List<double> rotPivLocal = [0, 0, 0];
  final List<double> scaPivLocal = [0, 0, 0];
  final List<OsGraphicItem> _children = [];
  WeakReference<OsGraphicItem>? _wparent;

  bool _selected = false;
  bool _selectable = false;
  WeakReference<OsRenderer>? _wselectInRenderer;
  late String _name;
  String _comment = '';
  late OsRenderItemType _type;

  /*@override
  void onDestroy() {
    if (_wselectInRenderer != null) {
      _wselectInRenderer!.destroy();
      _wselectInRenderer = null;
    }
    if (_wparent != null) {
      _wparent!.destroy();
      _wparent = null;
    }
    while (_children.isNotEmpty) {
      _children[0].setParent(null);
    }
    super.onDestroy();
  }*/

  OsGraphicItem? clone() => null;

  bool copyProperties(OsGraphicItem from) {
    visible = from.visible;
    inherits = from.inherits;
    _name = from._name;
    _comment = from._comment;
    _type = from._type;
    for (int i = 0; i < 3; i++) {
      pos[i] = from.pos[i];
      rot[i] = from.rot[i];
      sca[i] = from.sca[i];
      rotPiv[i] = from.rotPiv[i];
      scaPiv[i] = from.scaPiv[i];
      rotPivTrans[i] = from.rotPivTrans[i];
      scaPivTrans[i] = from.scaPivTrans[i];
      shear[i] = from.shear[i];
      rotAxe[i] = from.rotAxe[i];
      rotPivLocal[i] = from.rotPivLocal[i];
      scaPivLocal[i] = from.scaPivLocal[i];
    }
    validateMatrix();
    userData = from.userData;
    return true;
  }

  bool solveDependancies(OsItemDuplicateInfo info) => true;

  bool haveSameProperties(OsGraphicItem other) {
    if (_name != other._name) return false;
    if (_comment != other._comment) return false;
    if (_type != other._type) return false;
    if (active != other.active) return false;
    if (visible != other.visible) return false;
    if (inherits != other.inherits) return false;
    for (int i = 0; i < 3; i++) {
      if (pos[i] != other.pos[i]) return false;
      if (rot[i] != other.rot[i]) return false;
      if (sca[i] != other.sca[i]) return false;
      if (rotPiv[i] != other.rotPiv[i]) return false;
      if (scaPiv[i] != other.scaPiv[i]) return false;
      if (rotPivTrans[i] != other.rotPivTrans[i]) return false;
      if (scaPivTrans[i] != other.scaPivTrans[i]) return false;
      if (shear[i] != other.shear[i]) return false;
      if (rotAxe[i] != other.rotAxe[i]) return false;
      if (rotPivLocal[i] != other.rotPivLocal[i]) return false;
      if (scaPivLocal[i] != other.scaPivLocal[i]) return false;
    }
    if (userData.isNotEmpty || other.userData.isNotEmpty) {
      if (userData != other.userData) return false;
    }
    return true;
  }

  OsGraphicItem? getParent() {
    if (_wparent == null) return null;
    return _wparent!.target;
  }

  bool setParent(OsGraphicItem? parent) {
    final currentParent = getParent();
    if (currentParent == parent) return false;
    if (currentParent != null) {
      currentParent._children.remove(this);
    }
    if (parent != null) {
      parent._children.add(this);
      _wparent = WeakReference<OsGraphicItem>(parent);
    } else {
      _wparent = null;
    }
    return true;
  }

  List<OsGraphicItem> getChildren() => _children;

  void getChildrenByType(List<OsGraphicItem> list,
      [OsRenderItemType type = OsRenderItemType.osAnyItem,
      bool onlyDirect = true]) {
    for (final c in _children) {
      if (type == OsRenderItemType.osAnyItem || type == c._type) list.add(c);
      if (!onlyDirect) c.getChildrenByType(list, type, false);
    }
  }

  void validateMatrix() {
    if (sca[0].abs() < 1e-12) sca[0] = 1e-12;
    if (sca[1].abs() < 1e-12) sca[1] = 1e-12;
    if (sca[2].abs() < 1e-12) sca[2] = 1e-12;
    localMatrix.identity();
    localMatrix.translate(pos[0], pos[1], pos[2]);
    localMatrix.translate(rotPivTrans[0], rotPivTrans[1], rotPivTrans[2]);
    localMatrix.translate(rotPiv[0], rotPiv[1], rotPiv[2]);
    rotPivLocal[0] = localMatrix.mat[12];
    rotPivLocal[1] = localMatrix.mat[13];
    rotPivLocal[2] = localMatrix.mat[14];
    if (rot[2] != 0) localMatrix.rotateZ(rot[2] * 3.141592653589793 / 180.0);
    if (rot[1] != 0) localMatrix.rotateY(rot[1] * 3.141592653589793 / 180.0);
    if (rot[0] != 0) localMatrix.rotateX(rot[0] * 3.141592653589793 / 180.0);
    if (rotAxe[2] != 0) {
      localMatrix.rotateZ(rotAxe[2] * 3.141592653589793 / 180.0);
    }
    if (rotAxe[1] != 0) {
      localMatrix.rotateY(rotAxe[1] * 3.141592653589793 / 180.0);
    }
    if (rotAxe[0] != 0) {
      localMatrix.rotateX(rotAxe[0] * 3.141592653589793 / 180.0);
    }
    localMatrix.translate(-rotPiv[0], -rotPiv[1], -rotPiv[2]);
    localMatrix.translate(scaPivTrans[0], scaPivTrans[1], scaPivTrans[2]);
    localMatrix.translate(scaPiv[0], scaPiv[1], scaPiv[2]);
    scaPivLocal[0] = localMatrix.mat[12];
    scaPivLocal[1] = localMatrix.mat[13];
    scaPivLocal[2] = localMatrix.mat[14];
    final shearMat = OsMatrix();
    shearMat.mat[4] = shear[0];
    shearMat.mat[8] = shear[1];
    shearMat.mat[9] = shear[2];
    localMatrix.postMultiply(shearMat);
    localMatrix.scale(sca[0], sca[1], sca[2]);
    localMatrix.translate(-scaPiv[0], -scaPiv[1], -scaPiv[2]);
  }

  bool getWorldMatrix(OsMatrix mat, [OsRenderer? render]) {
    mat.identity();
    OsGraphicItem? node = this;
    while (node != null) {
      mat.preMultiply(node.localMatrix);
      node = node.getParent();
    }
    return true;
  }

  bool getWorldInvertMatrix(OsMatrix mat, [OsRenderer? render]) {
    if (!getWorldMatrix(mat, render)) return false;
    mat.invert();
    return true;
  }

  bool convertFromWorld(List<double> world, List<double> local,
      [OsRenderer? render]) {
    final imageMatInv = OsMatrix();
    if (!getWorldInvertMatrix(imageMatInv, render)) return false;
    local[0] = imageMatInv.mat[0] * world[0] +
        imageMatInv.mat[4] * world[1] +
        imageMatInv.mat[8] * world[2] +
        imageMatInv.mat[12];
    local[1] = imageMatInv.mat[1] * world[0] +
        imageMatInv.mat[5] * world[1] +
        imageMatInv.mat[9] * world[2] +
        imageMatInv.mat[13];
    local[2] = imageMatInv.mat[2] * world[0] +
        imageMatInv.mat[6] * world[1] +
        imageMatInv.mat[10] * world[2] +
        imageMatInv.mat[14];
    return true;
  }

  bool convertToWorld(List<double> local, List<double> world,
      [OsRenderer? render]) {
    final worldMatrix = OsMatrix();
    if (!getWorldMatrix(worldMatrix, render)) return false;
    world[0] = worldMatrix.mat[0] * local[0] +
        worldMatrix.mat[4] * local[1] +
        worldMatrix.mat[8] * local[2] +
        worldMatrix.mat[12];
    world[1] = worldMatrix.mat[1] * local[0] +
        worldMatrix.mat[5] * local[1] +
        worldMatrix.mat[9] * local[2] +
        worldMatrix.mat[13];
    world[2] = worldMatrix.mat[2] * local[0] +
        worldMatrix.mat[6] * local[1] +
        worldMatrix.mat[10] * local[2] +
        worldMatrix.mat[14];
    return true;
  }

  void willDraw(OsWillDrawInfo info, [bool propagate = false]) {
    if (propagate) {
      for (final c in _children) {
        c.willDraw(info, true);
      }
    }
  }

  void draw(OsDriver driver, OsRenderInfo info) {
    info.pushMatrix();
    info.applyWorldTransformation(localMatrix);
    for (final c in _children) {
      c.draw(driver, info);
    }
    info.popMatrix();
  }

  void reload(OsDriver driver) {}

  bool isDirty([bool propagate = false]) {
    if (propagate) {
      for (final c in _children) {
        if (c.isDirty(true)) return true;
      }
    }
    return false;
  }

  void setDirty(bool dirty) {}

  bool isSelectable() => _selectable;

  bool isSelected([OsRenderer? render]) {
    if (!_selected) return false;
    if (_wselectInRenderer != null) {
      if (_wselectInRenderer!.target == render) return true;
    }
    return false;
  }

  bool select(bool selected, [OsRenderer? render]) {
    if (!_selectable && selected) return false;
    if (selected) {
      if (render == null) return false;
      if (_selected) {
        if (_wselectInRenderer != null &&
            _wselectInRenderer!.target != render) {
          _wselectInRenderer = WeakReference<OsRenderer>(render);
          return true;
        }
        return false;
      } else {
        _selected = true;
        _wselectInRenderer = WeakReference<OsRenderer>(render);
        return true;
      }
    } else {
      if (!_selected) return false;
      if (render != null) {
        if (_wselectInRenderer != null &&
            _wselectInRenderer!.target == render) {
          _selected = false;
          _wselectInRenderer = null;
          return true;
        }
        return false;
      } else {
        _selected = false;
        _wselectInRenderer = null;
        return true;
      }
    }
  }

  void setSelectable(bool selectable) {
    _selectable = selectable;
  }

  void releaseMemory(IRenderer render, int level, [bool propagate = false]) {
    if (propagate) {
      for (final c in _children) {
        c.releaseMemory(render, level, true);
      }
    }
  }

  OsRenderItemType getType() => _type;
  String getName() => _name;
  String getComment() => _comment;

  bool setName(String name) {
    if (_name != name) {
      _name = name;
      return true;
    }
    return false;
  }

  void setComment(String comment) {
    _comment = comment;
  }

  void notifyChildrenAboutModification(OsRenderer render) {
    for (final c in _children) {
      c.onParentModified(render);
      c.notifyChildrenAboutModification(render);
    }
  }

  void onParentModified(OsRenderer render) {}

  void getDependencies(List<OsGraphicItem> list) {}

  bool getData(Map<String, dynamic> data, OsItemLoadInfo info) {
    if (_name.isNotEmpty) data['name'] = _name;
    if (_comment.isNotEmpty) data['comment'] = _comment;
    bool sameAsDefault = true;
    if (!active ||
        !visible ||
        !inherits ||
        pos[0] != 0 ||
        pos[1] != 0 ||
        pos[2] != 0 ||
        rot[0] != 0 ||
        rot[1] != 0 ||
        rot[2] != 0 ||
        sca[0] != 1 ||
        sca[1] != 1 ||
        sca[2] != 1 ||
        rotPiv[0] != 0 ||
        rotPiv[1] != 0 ||
        rotPiv[2] != 0 ||
        scaPiv[0] != 0 ||
        scaPiv[1] != 0 ||
        scaPiv[2] != 0 ||
        rotPivTrans[0] != 0 ||
        rotPivTrans[1] != 0 ||
        rotPivTrans[2] != 0 ||
        scaPivTrans[0] != 0 ||
        scaPivTrans[1] != 0 ||
        scaPivTrans[2] != 0 ||
        shear[0] != 0 ||
        shear[1] != 0 ||
        shear[2] != 0 ||
        rotAxe[0] != 0 ||
        rotAxe[1] != 0 ||
        rotAxe[2] != 0) {
      sameAsDefault = false;
    }
    if (!sameAsDefault) {
      data['active'] = active;
      data['visible'] = visible;
      data['inherits'] = inherits;
      data['pos'] = [pos[0], pos[1], pos[2]];
      data['rot'] = [rot[0], rot[1], rot[2]];
      data['sca'] = [sca[0], sca[1], sca[2]];
      data['rot_piv'] = [rotPiv[0], rotPiv[1], rotPiv[2]];
      data['sca_piv'] = [scaPiv[0], scaPiv[1], scaPiv[2]];
      data['rot_piv_trans'] = [rotPivTrans[0], rotPivTrans[1], rotPivTrans[2]];
      data['sca_piv_trans'] = [scaPivTrans[0], scaPivTrans[1], scaPivTrans[2]];
      data['shear'] = [shear[0], shear[1], shear[2]];
      data['rot_axe'] = [rotAxe[0], rotAxe[1], rotAxe[2]];
    }
    return true;
  }

  bool setData(Map<String, dynamic> data, OsItemLoadInfo info) {
    return true;
  }
}

///////////////////////////////////////////////////////////////////////
// OsItemDuplicateInfo
///////////////////////////////////////////////////////////////////////

class OsItemDuplicateInfo {
  OsGraphicItem? original;
  final List<OsGraphicItem> originalList = [];
  final List<OsGraphicItem?> duplicatedList = [];

  OsGraphicItem? findDuplicatedItem(OsGraphicItem orig) {
    for (int i = 0; i < originalList.length; i++) {
      if (originalList[i] == orig) {
        if (i >= 0 && i < duplicatedList.length) return duplicatedList[i];
      }
    }
    return null;
  }

  void clearDuplicatedList() {
    duplicatedList.clear();
  }
}

///////////////////////////////////////////////////////////////////////
// OsItemLoadInfo
///////////////////////////////////////////////////////////////////////

class OsItemLoadInfo {
  final List<(int, OsGraphicItem)> _data = [];

  void addItem(int uniqueId, OsGraphicItem item) {
    _data.add((uniqueId, item));
  }

  void removeItem(OsGraphicItem item) {
    for (int i = 0; i < _data.length; i++) {
      if (_data[i].$2 == item) {
        _data.removeAt(i);
        break;
      }
    }
  }

  OsGraphicItem? findItem(int uniqueId) {
    for (final e in _data) {
      if (e.$1 == uniqueId) return e.$2;
    }
    return null;
  }

  int findUniqueId(OsGraphicItem item) {
    for (final e in _data) {
      if (e.$2 == item) return e.$1;
    }
    return s32Max;
  }
}
