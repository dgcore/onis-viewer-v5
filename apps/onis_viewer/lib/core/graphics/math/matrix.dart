import 'dart:math' as math;

/// 4x4 matrix in column-major order (mat[0]..mat[15]).
class OsMatrix {
  final List<double> mat = List.filled(16, 0.0);

  OsMatrix() {
    identity();
  }

  void identity() {
    for (int i = 0; i < 16; i++) {
      mat[i] = 0.0;
    }
    mat[0] = mat[5] = mat[10] = mat[15] = 1.0;
  }

  void copyFrom(OsMatrix other) {
    for (int i = 0; i < 16; i++) {
      mat[i] = other.mat[i];
    }
  }

  void translate(double x, double y, double z) {
    mat[12] += x;
    mat[13] += y;
    mat[14] += z;
  }

  void rotateX(double radians) {
    final c = math.cos(radians), s = math.sin(radians);
    final m1 = mat[4], m2 = mat[5], m3 = mat[6];
    final m4 = mat[8], m5 = mat[9], m6 = mat[10];
    mat[4] = m1 * c + m4 * s;
    mat[5] = m2 * c + m5 * s;
    mat[6] = m3 * c + m6 * s;
    mat[8] = m4 * c - m1 * s;
    mat[9] = m5 * c - m2 * s;
    mat[10] = m6 * c - m3 * s;
  }

  void rotateY(double radians) {
    final c = math.cos(radians), s = math.sin(radians);
    final m0 = mat[0], m1 = mat[1], m2 = mat[2];
    final m8 = mat[8], m9 = mat[9], m10 = mat[10];
    mat[0] = m0 * c - m8 * s;
    mat[1] = m1 * c - m9 * s;
    mat[2] = m2 * c - m10 * s;
    mat[8] = m0 * s + m8 * c;
    mat[9] = m1 * s + m9 * c;
    mat[10] = m2 * s + m10 * c;
  }

  void rotateZ(double radians) {
    final c = math.cos(radians), s = math.sin(radians);
    final m0 = mat[0], m1 = mat[1], m2 = mat[2];
    final m4 = mat[4], m5 = mat[5], m6 = mat[6];
    mat[0] = m0 * c + m4 * s;
    mat[1] = m1 * c + m5 * s;
    mat[2] = m2 * c + m6 * s;
    mat[4] = m4 * c - m0 * s;
    mat[5] = m5 * c - m1 * s;
    mat[6] = m6 * c - m2 * s;
  }

  void scale(double x, double y, double z) {
    mat[0] *= x;
    mat[1] *= x;
    mat[2] *= x;
    mat[4] *= y;
    mat[5] *= y;
    mat[6] *= y;
    mat[8] *= z;
    mat[9] *= z;
    mat[10] *= z;
  }

  void preMultiply(OsMatrix other) {
    final a = other.mat;
    final b = mat;
    final r = List<double>.filled(16, 0.0);
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        r[col * 4 + row] = a[row] * b[col * 4 + 0] +
            a[row + 4] * b[col * 4 + 1] +
            a[row + 8] * b[col * 4 + 2] +
            a[row + 12] * b[col * 4 + 3];
      }
    }
    for (int i = 0; i < 16; i++) {
      mat[i] = r[i];
    }
  }

  void postMultiply(OsMatrix other) {
    final a = mat;
    final b = other.mat;
    final r = List<double>.filled(16, 0.0);
    for (int col = 0; col < 4; col++) {
      for (int row = 0; row < 4; row++) {
        r[col * 4 + row] = a[row] * b[col * 4 + 0] +
            a[row + 4] * b[col * 4 + 1] +
            a[row + 8] * b[col * 4 + 2] +
            a[row + 12] * b[col * 4 + 3];
      }
    }
    for (int i = 0; i < 16; i++) {
      mat[i] = r[i];
    }
  }

  void buildOrthographicProjectionMatrixRH(
    double left,
    double right,
    double bottom,
    double top,
    double near,
    double far,
  ) {
    identity();
    mat[0] = 2.0 / (right - left);
    mat[5] = 2.0 / (top - bottom);
    mat[10] = -2.0 / (far - near);
    mat[12] = -(right + left) / (right - left);
    mat[13] = -(top + bottom) / (top - bottom);
    mat[14] = -(far + near) / (far - near);
    mat[15] = 1.0;
  }

  void getInvert(OsMatrix output) {
    output.copyFrom(this);
    output.invert();
  }

  void getTransposed(OsMatrix output) {
    output.copyFrom(this);
    output.transpose();
  }

  void transpose() {
    final m = mat;
    final trans = List<double>.filled(16, 0.0);
    trans[0] = m[0];
    trans[1] = m[4];
    trans[2] = m[8];
  }

  void invert() {
    // Minimal 4x4 invert (assumes affine 3D transform).
    final m = mat;
    final inv = List<double>.filled(16, 0.0);
    inv[0] = m[5] * m[10] - m[6] * m[9];
    inv[1] = m[2] * m[9] - m[1] * m[10];
    inv[2] = m[1] * m[6] - m[2] * m[5];
    inv[4] = m[6] * m[8] - m[4] * m[10];
    inv[5] = m[0] * m[10] - m[2] * m[8];
    inv[6] = m[2] * m[4] - m[0] * m[6];
    inv[8] = m[4] * m[9] - m[5] * m[8];
    inv[9] = m[1] * m[8] - m[0] * m[9];
    inv[10] = m[0] * m[5] - m[1] * m[4];
    inv[15] = 1.0;
    double det = m[0] * inv[0] + m[1] * inv[4] + m[2] * inv[8];
    if (det.abs() < 1e-12) return;
    det = 1.0 / det;
    inv[12] = -(m[12] * inv[0] + m[13] * inv[4] + m[14] * inv[8]) * det;
    inv[13] = -(m[12] * inv[1] + m[13] * inv[5] + m[14] * inv[9]) * det;
    inv[14] = -(m[12] * inv[2] + m[13] * inv[6] + m[14] * inv[10]) * det;
    for (int i = 0; i < 11; i++) {
      inv[i] *= det;
    }
    for (int i = 0; i < 16; i++) {
      mat[i] = inv[i];
    }
  }
}
