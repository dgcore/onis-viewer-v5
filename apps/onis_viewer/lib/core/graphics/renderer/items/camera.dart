import 'dart:math' as math;

import 'package:onis_viewer/core/graphics/renderer/items/item.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/math/vector3d.dart';

enum OsCameraType {
  camera,
  cameraAim,
  cameraAimUp,
}

enum OsCameraView {
  perspective,
  front,
  top,
  side,
}

enum OsFilmGate {
  user,
  f16,
  super16,
  f35aca,
  f35tv,
  f35full,
  f35_185proj,
  f35ana,
  f70proj,
  vista,
  imax,
}

enum OsFilmFit {
  horizontal,
  vertical,
}

class OsGraphicCamera extends OsGraphicItem {
  double _angle;
  double _focal;
  double _far;
  double _near;
  final List<double> _aperture = [0.0, 0.0];
  double _centerOfInterest;
  bool _orthographic;
  double _orthoWidth;
  OsCameraType _camType;
  OsFilmGate _filmBack;
  OsFilmFit _fitType;
  bool _modify;
  final OsMatrix _projectionMatrix = OsMatrix();

  OsGraphicCamera([String name = ''])
      : _angle = 0.0,
        _focal = 35.0,
        _far = 1000.0,
        _near = 0.1,
        _centerOfInterest = 5.0,
        _orthographic = false,
        _orthoWidth = 100.0,
        _camType = OsCameraType.camera,
        _filmBack = OsFilmGate.user,
        _fitType = OsFilmFit.horizontal,
        _modify = false,
        super(type: OsRenderItemType.osCameraItem, name: name) {
    _aperture[0] = 1.4173;
    _aperture[1] = 0.9449;
    _angle = _calculateAngle();
  }

  @override
  OsGraphicItem clone() {
    final cam = OsGraphicCamera(getName());
    cam.copyProperties(this);
    return cam;
  }

  @override
  bool copyProperties(OsGraphicItem from) {
    final ret = super.copyProperties(from);
    final source = from as OsGraphicCamera;
    _angle = source._angle;
    _focal = source._focal;
    _far = source._far;
    _near = source._near;
    _aperture[0] = source._aperture[0];
    _aperture[1] = source._aperture[1];
    _centerOfInterest = source._centerOfInterest;
    _orthographic = source._orthographic;
    _orthoWidth = source._orthoWidth;
    _camType = source._camType;
    _filmBack = source._filmBack;
    _fitType = source._fitType;
    _projectionMatrix.copyFrom(source._projectionMatrix);
    _modify = source._modify;
    return ret;
  }

  @override
  bool haveSameProperties(OsGraphicItem other) {
    if (!super.haveSameProperties(other)) {
      return false;
    }
    final source = other as OsGraphicCamera;
    if (_angle != source._angle) return false;
    if (_focal != source._focal) return false;
    if (_far != source._far) return false;
    if (_near != source._near) return false;
    if (_aperture[0] != source._aperture[0]) return false;
    if (_aperture[1] != source._aperture[1]) return false;
    if (_centerOfInterest != source._centerOfInterest) return false;
    if (_orthographic != source._orthographic) return false;
    if (_orthoWidth != source._orthoWidth) return false;
    if (_camType != source._camType) return false;
    if (_filmBack != source._filmBack) return false;
    if (_fitType != source._fitType) return false;
    if (_modify != source._modify) return false;
    return true;
  }

  void setAngle(double val) {
    if (val < 1.0) {
      val = 1.0;
    } else if (val > 165.0) {
      val = 165.0;
    }
    _angle = val;
    _focal = _calculateFocal();
  }

  void setFocal(double val) {
    if (val < 0) {
      val = 0;
    }
    _focal = val;
    setAngle(_calculateAngle());
  }

  double getAngle() => _angle;

  double getFocal() => _focal;

  bool isOrthographicMode() => _orthographic;

  void setOrthographicMode(bool ortho) {
    _orthographic = ortho;
  }

  double getOrthoWidth() => _orthoWidth;

  void setOrthoWidth(double width) {
    _orthoWidth = width;
  }

  void setFilmGateType(OsFilmGate type) {
    _filmBack = type;
    if (type == OsFilmGate.user) {
      return;
    }

    switch (type) {
      case OsFilmGate.f16:
        _aperture[0] = 0.404;
        _aperture[1] = 0.295;
        break;
      case OsFilmGate.super16:
        _aperture[0] = 0.493;
        _aperture[1] = 0.292;
        break;
      case OsFilmGate.f35aca:
        _aperture[0] = 0.864;
        _aperture[1] = 0.630;
        break;
      case OsFilmGate.f35tv:
        _aperture[0] = 0.816;
        _aperture[1] = 0.612;
        break;
      case OsFilmGate.f35full:
        _aperture[0] = 0.980;
        _aperture[1] = 0.735;
        break;
      case OsFilmGate.f35_185proj:
        _aperture[0] = 0.825;
        _aperture[1] = 0.446;
        break;
      case OsFilmGate.f35ana:
        _aperture[0] = 0.864;
        _aperture[1] = 0.732;
        break;
      case OsFilmGate.f70proj:
        _aperture[0] = 2.066;
        _aperture[1] = 0.906;
        break;
      case OsFilmGate.vista:
        _aperture[0] = 1.485;
        _aperture[1] = 0.991;
        break;
      case OsFilmGate.imax:
        _aperture[0] = 2.772;
        _aperture[1] = 2.072;
        break;
      case OsFilmGate.user:
        break;
    }
    _angle = _calculateAngle();
  }

  void setCameraApertureHoriz(double value) {
    setFilmGateType(OsFilmGate.user);
    _aperture[0] = value;
    _angle = _calculateAngle();
  }

  void setCameraApertureVert(double value) {
    setFilmGateType(OsFilmGate.user);
    _aperture[1] = value;
  }

  void setFilmFitting(OsFilmFit type) {
    _fitType = type;
  }

  OsFilmGate getFilmGateType() => _filmBack;

  OsFilmFit getFilmFittingType() => _fitType;

  void getCameraAperture(List<double> output) {
    output[0] = _aperture[0];
    output[1] = _aperture[1];
  }

  double getNearPlane() => _near;

  double getFarPlane() => _far;

  void setNearPlane(double value) {
    _near = value;
  }

  void setFarPlane(double value) {
    _far = value;
  }

  OsMatrix getProjectionMatrix(double ratio) {
    if (_orthographic) {
      final halfWidth = _orthoWidth * 0.5;
      final halfHeight = ratio * halfWidth;
      _projectionMatrix.buildOrthographicProjectionMatrixRH(
        -halfWidth,
        halfWidth,
        -halfHeight,
        halfHeight,
        _near,
        _far,
      );
    } else {
      double angle;
      if (_fitType == OsFilmFit.horizontal) {
        angle = 0.5 * _angle * math.pi / 180.0;
        angle = 2.0 * math.atan(math.tan(angle) * ratio) * 180.0 / math.pi;
      } else {
        angle =
            2.0 * math.atan((_aperture[1] * 12.7) / _focal) * 180.0 / math.pi;
      }
      final invRatio = ratio != 0 ? 1.0 / ratio : 1.0;
      _projectionMatrix.buildPerspectiveProjectionMatrixRH(
        angle,
        invRatio,
        _near,
        _far,
      );
    }
    return _projectionMatrix;
  }

  bool convertMouseCursorToWorld(
    double x,
    double y,
    double width,
    double height,
    List<double> world,
  ) {
    if (!_orthographic) {
      return false;
    }

    final win = [x, y, 0.0];
    final modelView = OsMatrix();
    getWorldInvertMatrix(modelView, null);

    final viewport = [0.0, 0.0, width, height];
    if (width == 0.0) {
      return false;
    }

    final ratio = height / width;
    final proj = getProjectionMatrix(ratio);
    return OsVec3D.unproject(win, modelView, proj, viewport, world);
  }

  bool convertWorldToMouseCursor(
    List<double> world,
    double width,
    double height,
    List<double> xy,
  ) {
    final modelView = OsMatrix();
    getWorldInvertMatrix(modelView, null);

    final viewport = [0.0, 0.0, width, height];
    if (viewport[2] == 0.0) {
      return false;
    }

    final ratio = height / width;
    final proj = getProjectionMatrix(ratio);
    final win = [0.0, 0.0, 0.0];

    if (OsVec3D.project(world, modelView, proj, viewport, win)) {
      xy[0] = win[0];
      xy[1] = win[1];
      return true;
    }
    return false;
  }

  bool getModify() => _modify;

  void setModify(bool modify) {
    _modify = modify;
  }

  double _calculateAngle() {
    if (_focal == 0) {
      return 180.0;
    }
    return 2.0 * (math.atan((12.7 * _aperture[0]) / _focal) * 180.0 / math.pi);
  }

  double _calculateFocal() {
    if (_angle == 180.0) {
      return 0.0;
    }
    return (12.7 * _aperture[0]) / math.tan((_angle * math.pi / 180.0) / 2.0);
  }
}
