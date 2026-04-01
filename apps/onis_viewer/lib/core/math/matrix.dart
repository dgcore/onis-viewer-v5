import 'dart:math' as math;

class OsMatrix {
  List<double> mat;

  OsMatrix()
      : mat = [
          1.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
          0.0,
          0.0,
          0.0,
          0.0,
          1.0,
        ];

  void identity() {
    mat[0] = 1.0;
    mat[4] = 0.0;
    mat[8] = 0.0;
    mat[12] = 0.0;
    mat[1] = 0.0;
    mat[5] = 1.0;
    mat[9] = 0.0;
    mat[13] = 0.0;
    mat[2] = 0.0;
    mat[6] = 0.0;
    mat[10] = 1.0;
    mat[14] = 0.0;
    mat[3] = 0.0;
    mat[7] = 0.0;
    mat[11] = 0.0;
    mat[15] = 1.0;
  }

  void copyFrom(OsMatrix other) {
    for (int i = 0; i < 16; i++) {
      mat[i] = other.mat[i];
    }
  }

  void translate(double x, double y, double z) {
    mat[12] = mat[0] * x + mat[4] * y + mat[8] * z + mat[12];
    mat[13] = mat[1] * x + mat[5] * y + mat[9] * z + mat[13];
    mat[14] = mat[2] * x + mat[6] * y + mat[10] * z + mat[14];
  }

  void rotateX(double rot) {
    rot = -rot;
    double temp = mat[4];
    mat[4] = mat[4] * math.cos(rot) - mat[8] * math.sin(rot);
    mat[8] = temp * math.sin(rot) + mat[8] * math.cos(rot);

    temp = mat[5];
    mat[5] = mat[5] * math.cos(rot) - mat[9] * math.sin(rot);
    mat[9] = temp * math.sin(rot) + mat[9] * math.cos(rot);

    temp = mat[6];
    mat[6] = mat[6] * math.cos(rot) - mat[10] * math.sin(rot);
    mat[10] = temp * math.sin(rot) + mat[10] * math.cos(rot);
  }

  void rotateY(double rot) {
    double temp = mat[0];
    mat[0] = mat[0] * math.cos(rot) - mat[8] * math.sin(rot);
    mat[8] = temp * math.sin(rot) + mat[8] * math.cos(rot);

    temp = mat[1];
    mat[1] = mat[1] * math.cos(rot) - mat[9] * math.sin(rot);
    mat[9] = temp * math.sin(rot) + mat[9] * math.cos(rot);

    temp = mat[2];
    mat[2] = mat[2] * math.cos(rot) - mat[10] * math.sin(rot);
    mat[10] = temp * math.sin(rot) + mat[10] * math.cos(rot);
  }

  void rotateZ(double rot) {
    rot = -rot;
    double temp = mat[0];
    mat[0] = mat[0] * math.cos(rot) - mat[4] * math.sin(rot);
    mat[4] = temp * math.sin(rot) + mat[4] * math.cos(rot);

    temp = mat[1];
    mat[1] = mat[1] * math.cos(rot) - mat[5] * math.sin(rot);
    mat[5] = temp * math.sin(rot) + mat[5] * math.cos(rot);

    temp = mat[2];
    mat[2] = mat[2] * math.cos(rot) - mat[6] * math.sin(rot);
    mat[6] = temp * math.sin(rot) + mat[6] * math.cos(rot);
  }

  void scale(double x, double y, double z) {
    mat[0] *= x;
    mat[1] *= x;
    mat[2] *= x;
    mat[3] *= x;
    mat[4] *= y;
    mat[5] *= y;
    mat[6] *= y;
    mat[7] *= y;
    mat[8] *= z;
    mat[9] *= z;
    mat[10] *= z;
    mat[11] *= z;
  }

  void buildOrthographicProjectionMatrixRH(
    double left,
    double right,
    double bottom,
    double top,
    double nearPlane,
    double farPlane,
  ) {
    final double deltaX = right - left;
    final double deltaY = top - bottom;
    final double deltaZ = farPlane - nearPlane;

    identity();
    mat[0] = 2.0 / deltaX;
    mat[12] = -(right + left) / deltaX;
    mat[5] = 2.0 / deltaY;
    mat[13] = -(top + bottom) / deltaY;
    mat[10] = -2.0 / deltaZ;
    mat[14] = -(nearPlane + farPlane) / deltaZ;
  }

  void buildPerspectiveProjectionMatrixRH(
    double angle,
    double aspectRatio,
    double nearPlane,
    double farPlane,
  ) {
    final double frustumH = math.tan((angle * math.pi) / 360.0) * nearPlane;
    final double frustumW = frustumH * aspectRatio;
    final double right = frustumW;
    final double left = -frustumW;
    final double top = frustumH;
    final double bottom = -frustumH;
    final double deltaX = right - left;
    final double deltaY = top - bottom;
    final double deltaZ = farPlane - nearPlane;

    mat[0] = 2.0 * nearPlane / deltaX;
    mat[1] = 0.0;
    mat[2] = 0.0;
    mat[3] = 0.0;

    mat[5] = 2.0 * nearPlane / deltaY;
    mat[4] = 0.0;
    mat[6] = 0.0;
    mat[7] = 0.0;

    mat[8] = (right + left) / deltaX;
    mat[9] = (top + bottom) / deltaY;
    mat[10] = -(nearPlane + farPlane) / deltaZ;
    mat[11] = -1.0;
    mat[14] = -2.0 * nearPlane * farPlane / deltaZ;
    mat[12] = 0.0;
    mat[13] = 0.0;
    mat[15] = 0.0;

    mat[15] = 1.0;
  }

  void preMultiply(OsMatrix other) {
    final List<double> res = [
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ];

    res[0] = other.mat[0] * mat[0] +
        other.mat[4] * mat[1] +
        other.mat[8] * mat[2] +
        other.mat[12] * mat[3];
    res[1] = other.mat[1] * mat[0] +
        other.mat[5] * mat[1] +
        other.mat[9] * mat[2] +
        other.mat[13] * mat[3];
    res[2] = other.mat[2] * mat[0] +
        other.mat[6] * mat[1] +
        other.mat[10] * mat[2] +
        other.mat[14] * mat[3];
    res[3] = other.mat[3] * mat[0] +
        other.mat[7] * mat[1] +
        other.mat[11] * mat[2] +
        other.mat[15] * mat[3];

    res[4] = other.mat[0] * mat[4] +
        other.mat[4] * mat[5] +
        other.mat[8] * mat[6] +
        other.mat[12] * mat[7];
    res[5] = other.mat[1] * mat[4] +
        other.mat[5] * mat[5] +
        other.mat[9] * mat[6] +
        other.mat[13] * mat[7];
    res[6] = other.mat[2] * mat[4] +
        other.mat[6] * mat[5] +
        other.mat[10] * mat[6] +
        other.mat[14] * mat[7];
    res[7] = other.mat[3] * mat[4] +
        other.mat[7] * mat[5] +
        other.mat[11] * mat[6] +
        other.mat[15] * mat[7];

    res[8] = other.mat[0] * mat[8] +
        other.mat[4] * mat[9] +
        other.mat[8] * mat[10] +
        other.mat[12] * mat[11];
    res[9] = other.mat[1] * mat[8] +
        other.mat[5] * mat[9] +
        other.mat[9] * mat[10] +
        other.mat[13] * mat[11];
    res[10] = other.mat[2] * mat[8] +
        other.mat[6] * mat[9] +
        other.mat[10] * mat[10] +
        other.mat[14] * mat[11];
    res[11] = other.mat[3] * mat[8] +
        other.mat[7] * mat[9] +
        other.mat[11] * mat[10] +
        other.mat[15] * mat[11];

    res[12] = other.mat[0] * mat[12] +
        other.mat[4] * mat[13] +
        other.mat[8] * mat[14] +
        other.mat[12] * mat[15];
    res[13] = other.mat[1] * mat[12] +
        other.mat[5] * mat[13] +
        other.mat[9] * mat[14] +
        other.mat[13] * mat[15];
    res[14] = other.mat[2] * mat[12] +
        other.mat[6] * mat[13] +
        other.mat[10] * mat[14] +
        other.mat[14] * mat[15];
    res[15] = other.mat[3] * mat[12] +
        other.mat[7] * mat[13] +
        other.mat[11] * mat[14] +
        other.mat[15] * mat[15];

    for (int i = 0; i < 16; i++) {
      mat[i] = res[i];
    }
  }

  void postMultiply(OsMatrix other) {
    final List<double> res = [
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
    ];

    res[0] = mat[0] * other.mat[0] +
        mat[4] * other.mat[1] +
        mat[8] * other.mat[2] +
        mat[12] * other.mat[3];
    res[1] = mat[1] * other.mat[0] +
        mat[5] * other.mat[1] +
        mat[9] * other.mat[2] +
        mat[13] * other.mat[3];
    res[2] = mat[2] * other.mat[0] +
        mat[6] * other.mat[1] +
        mat[10] * other.mat[2] +
        mat[14] * other.mat[3];
    res[3] = mat[3] * other.mat[0] +
        mat[7] * other.mat[1] +
        mat[11] * other.mat[2] +
        mat[15] * other.mat[3];

    res[4] = mat[0] * other.mat[4] +
        mat[4] * other.mat[5] +
        mat[8] * other.mat[6] +
        mat[12] * other.mat[7];
    res[5] = mat[1] * other.mat[4] +
        mat[5] * other.mat[5] +
        mat[9] * other.mat[6] +
        mat[13] * other.mat[7];
    res[6] = mat[2] * other.mat[4] +
        mat[6] * other.mat[5] +
        mat[10] * other.mat[6] +
        mat[14] * other.mat[7];
    res[7] = mat[3] * other.mat[4] +
        mat[7] * other.mat[5] +
        mat[11] * other.mat[6] +
        mat[15] * other.mat[7];

    res[8] = mat[0] * other.mat[8] +
        mat[4] * other.mat[9] +
        mat[8] * other.mat[10] +
        mat[12] * other.mat[11];
    res[9] = mat[1] * other.mat[8] +
        mat[5] * other.mat[9] +
        mat[9] * other.mat[10] +
        mat[13] * other.mat[11];
    res[10] = mat[2] * other.mat[8] +
        mat[6] * other.mat[9] +
        mat[10] * other.mat[10] +
        mat[14] * other.mat[11];
    res[11] = mat[3] * other.mat[8] +
        mat[7] * other.mat[9] +
        mat[11] * other.mat[10] +
        mat[15] * other.mat[11];

    res[12] = mat[0] * other.mat[12] +
        mat[4] * other.mat[13] +
        mat[8] * other.mat[14] +
        mat[12] * other.mat[15];
    res[13] = mat[1] * other.mat[12] +
        mat[5] * other.mat[13] +
        mat[9] * other.mat[14] +
        mat[13] * other.mat[15];
    res[14] = mat[2] * other.mat[12] +
        mat[6] * other.mat[13] +
        mat[10] * other.mat[14] +
        mat[14] * other.mat[15];
    res[15] = mat[3] * other.mat[12] +
        mat[7] * other.mat[13] +
        mat[11] * other.mat[14] +
        mat[15] * other.mat[15];

    for (int i = 0; i < 16; i++) {
      mat[i] = res[i];
    }
  }

  void getInvert(OsMatrix other) {
    double det = mat[0] * mat[5] * mat[10] +
        mat[1] * mat[6] * mat[8] +
        mat[2] * mat[4] * mat[9] -
        mat[8] * mat[5] * mat[2] -
        mat[9] * mat[6] * mat[0] -
        mat[10] * mat[4] * mat[1];

    if (det == 0.0) {
      return;
    }
    det = 1.0 / det;

    other.mat[0] = det *
        (mat[5] * mat[10] * mat[15] +
            mat[6] * mat[11] * mat[13] +
            mat[7] * mat[9] * mat[14] -
            mat[7] * mat[10] * mat[13] -
            mat[11] * mat[14] * mat[5] -
            mat[15] * mat[6] * mat[9]);
    other.mat[4] = -det *
        (mat[4] * mat[10] * mat[15] +
            mat[6] * mat[11] * mat[12] +
            mat[7] * mat[8] * mat[14] -
            mat[7] * mat[10] * mat[12] -
            mat[11] * mat[14] * mat[4] -
            mat[15] * mat[6] * mat[8]);
    other.mat[8] = det *
        (mat[4] * mat[9] * mat[15] +
            mat[5] * mat[11] * mat[12] +
            mat[7] * mat[8] * mat[13] -
            mat[7] * mat[9] * mat[12] -
            mat[11] * mat[13] * mat[4] -
            mat[15] * mat[5] * mat[8]);
    other.mat[12] = -det *
        (mat[4] * mat[9] * mat[14] +
            mat[5] * mat[10] * mat[12] +
            mat[6] * mat[8] * mat[13] -
            mat[6] * mat[9] * mat[12] -
            mat[10] * mat[13] * mat[4] -
            mat[14] * mat[5] * mat[8]);

    other.mat[1] = -det *
        (mat[1] * mat[10] * mat[15] +
            mat[2] * mat[11] * mat[13] +
            mat[3] * mat[9] * mat[14] -
            mat[3] * mat[10] * mat[13] -
            mat[11] * mat[14] * mat[1] -
            mat[15] * mat[2] * mat[9]);
    other.mat[5] = det *
        (mat[0] * mat[10] * mat[15] +
            mat[2] * mat[11] * mat[12] +
            mat[3] * mat[8] * mat[14] -
            mat[3] * mat[10] * mat[12] -
            mat[11] * mat[14] * mat[8] -
            mat[15] * mat[2] * mat[8]);
    other.mat[9] = -det *
        (mat[0] * mat[9] * mat[15] +
            mat[1] * mat[11] * mat[12] +
            mat[3] * mat[8] * mat[13] -
            mat[3] * mat[9] * mat[12] -
            mat[11] * mat[13] * mat[0] -
            mat[15] * mat[1] * mat[8]);
    other.mat[13] = det *
        (mat[0] * mat[9] * mat[14] +
            mat[1] * mat[10] * mat[12] +
            mat[2] * mat[8] * mat[13] -
            mat[2] * mat[9] * mat[12] -
            mat[10] * mat[13] * mat[0] -
            mat[14] * mat[1] * mat[8]);

    other.mat[2] = det *
        (mat[1] * mat[6] * mat[15] +
            mat[2] * mat[7] * mat[13] +
            mat[3] * mat[5] * mat[14] -
            mat[3] * mat[6] * mat[13] -
            mat[7] * mat[14] * mat[1] -
            mat[15] * mat[2] * mat[5]);
    other.mat[6] = -det *
        (mat[0] * mat[6] * mat[15] +
            mat[2] * mat[7] * mat[12] +
            mat[3] * mat[4] * mat[14] -
            mat[3] * mat[6] * mat[12] -
            mat[7] * mat[14] * mat[0] -
            mat[15] * mat[2] * mat[4]);
    other.mat[10] = det *
        (mat[0] * mat[5] * mat[15] +
            mat[1] * mat[7] * mat[12] +
            mat[3] * mat[4] * mat[13] -
            mat[3] * mat[5] * mat[12] -
            mat[7] * mat[13] * mat[0] -
            mat[15] * mat[1] * mat[4]);
    other.mat[14] = -det *
        (mat[0] * mat[5] * mat[14] +
            mat[1] * mat[6] * mat[12] +
            mat[2] * mat[4] * mat[13] -
            mat[2] * mat[5] * mat[12] -
            mat[6] * mat[13] * mat[0] -
            mat[14] * mat[1] * mat[4]);

    other.mat[3] = -det *
        (mat[1] * mat[6] * mat[11] +
            mat[2] * mat[7] * mat[9] +
            mat[3] * mat[5] * mat[10] -
            mat[3] * mat[6] * mat[9] -
            mat[7] * mat[10] * mat[1] -
            mat[11] * mat[2] * mat[5]);
    other.mat[7] = det *
        (mat[0] * mat[6] * mat[11] +
            mat[2] * mat[7] * mat[8] +
            mat[3] * mat[4] * mat[10] -
            mat[3] * mat[6] * mat[8] -
            mat[7] * mat[10] * mat[0] -
            mat[11] * mat[2] * mat[4]);
    other.mat[11] = -det *
        (mat[0] * mat[5] * mat[11] +
            mat[1] * mat[7] * mat[8] +
            mat[3] * mat[4] * mat[9] -
            mat[3] * mat[5] * mat[8] -
            mat[7] * mat[9] * mat[0] -
            mat[11] * mat[1] * mat[4]);
    other.mat[15] = det *
        (mat[0] * mat[5] * mat[10] +
            mat[1] * mat[6] * mat[8] +
            mat[2] * mat[4] * mat[9] -
            mat[2] * mat[5] * mat[8] -
            mat[6] * mat[9] * mat[0] -
            mat[10] * mat[1] * mat[4]);
  }

  void getTransposed(OsMatrix other) {
    other.mat[0] = mat[0];
    other.mat[1] = mat[4];
    other.mat[2] = mat[8];
    other.mat[3] = mat[12];

    other.mat[4] = mat[1];
    other.mat[5] = mat[5];
    other.mat[6] = mat[9];
    other.mat[7] = mat[13];

    other.mat[8] = mat[2];
    other.mat[9] = mat[6];
    other.mat[10] = mat[10];
    other.mat[11] = mat[14];

    other.mat[12] = mat[3];
    other.mat[13] = mat[7];
    other.mat[14] = mat[11];
    other.mat[15] = mat[15];
  }

  void invert() {
    final OsMatrix other = OsMatrix();
    getInvert(other);
    for (int i = 0; i < 16; i++) {
      mat[i] = other.mat[i];
    }
  }

  bool isEqual(OsMatrix other) {
    for (int i = 0; i < 16; i++) {
      if (mat[i] != other.mat[i]) {
        return false;
      }
    }
    return true;
  }
}
