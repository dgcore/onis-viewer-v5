import 'dart:math' as math;

import 'matrix.dart';

class OsVec3D {
  static double getVectorLength(List<double> vec) {
    final double len = vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2];
    return math.sqrt(len);
  }

  static double getLength(List<double> pt1, List<double> pt2) {
    final double len = (pt1[0] - pt2[0]) * (pt1[0] - pt2[0]) +
        (pt1[1] - pt2[1]) * (pt1[1] - pt2[1]) +
        (pt1[2] - pt2[2]) * (pt1[2] - pt2[2]);
    return math.sqrt(len);
  }

  static double normalize(List<double> vec) {
    final double len =
        math.sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    if (len > 0) {
      final double inv = 1.0 / len;
      vec[0] *= inv;
      vec[1] *= inv;
      vec[2] *= inv;
      return len;
    } else {
      return 0.0;
    }
  }

  static double normalizeMatVec(OsMatrix mat, int index) {
    final double len = math.sqrt(
      mat.mat[index] * mat.mat[index] +
          mat.mat[index + 1] * mat.mat[index + 1] +
          mat.mat[index + 2] * mat.mat[index + 2],
    );

    if (len > 0) {
      final double inv = 1.0 / len;
      mat.mat[index] *= inv;
      mat.mat[index + 1] *= inv;
      mat.mat[index + 2] *= inv;
      return len;
    } else {
      return 0.0;
    }
  }

  static void vectorialProduct(
    List<double> vec1,
    List<double> vec2,
    List<double> output,
  ) {
    output[0] = vec1[1] * vec2[2] - vec1[2] * vec2[1];
    output[1] = vec1[2] * vec2[0] - vec1[0] * vec2[2];
    output[2] = vec1[0] * vec2[1] - vec1[1] * vec2[0];
  }

  static void vectorialProductFromMat(
    OsMatrix mat,
    int index1,
    int index2,
    int index3,
  ) {
    mat.mat[index3] = mat.mat[index1 + 1] * mat.mat[index2 + 2] -
        mat.mat[index1 + 2] * mat.mat[index2 + 1];
    mat.mat[index3 + 1] = mat.mat[index1 + 2] * mat.mat[index2] -
        mat.mat[index1] * mat.mat[index2 + 2];
    mat.mat[index3 + 2] = mat.mat[index1] * mat.mat[index2 + 1] -
        mat.mat[index1 + 1] * mat.mat[index2];
  }

  static double scalarProduct(List<double> vec1, List<double> vec2) {
    return vec1[0] * vec2[0] + vec1[1] * vec2[1] + vec1[2] * vec2[2];
  }

  static double scalarProductWidthOffset(
    List<double> vec1,
    int offset1,
    List<double> vec2,
    int offset2,
  ) {
    return vec1[offset1] * vec2[offset2] +
        vec1[offset1 + 1] * vec2[offset2 + 1] +
        vec1[offset1 + 2] * vec2[offset2 + 2];
  }

  static bool getKFactorByOffset(
    List<double> base,
    int baseOffset,
    List<double> vec,
    List<double> pt,
    int ptOffset,
    List<double> k,
  ) {
    final double a = vec[0];
    final double b = vec[1];
    final double c = vec[2];
    final double d = -a * base[baseOffset] -
        b * base[baseOffset + 1] -
        c * base[baseOffset + 2];

    final double ratio = a * a + b * b + c * c;
    if (ratio.abs() < 0.0001) {
      return false;
    }

    k[0] =
        (a * pt[ptOffset] + b * pt[ptOffset + 1] + c * pt[ptOffset + 2] + d) /
            ratio;
    return true;
  }

  static bool project(
    List<double> obj,
    OsMatrix modelView,
    OsMatrix projection,
    List<double> viewport,
    List<double> win,
  ) {
    final List<double> tmp = [0.0, 0.0, 0.0, 0.0];
    final List<double> out = [0.0, 0.0, 0.0, 0.0];

    tmp[0] = modelView.mat[0] * obj[0] +
        modelView.mat[4] * obj[1] +
        modelView.mat[8] * obj[2] +
        modelView.mat[12];
    tmp[1] = modelView.mat[1] * obj[0] +
        modelView.mat[5] * obj[1] +
        modelView.mat[9] * obj[2] +
        modelView.mat[13];
    tmp[2] = modelView.mat[2] * obj[0] +
        modelView.mat[6] * obj[1] +
        modelView.mat[10] * obj[2] +
        modelView.mat[14];
    tmp[3] = modelView.mat[3] * obj[0] +
        modelView.mat[7] * obj[1] +
        modelView.mat[11] * obj[2] +
        modelView.mat[15];

    out[0] = projection.mat[0] * tmp[0] +
        projection.mat[4] * tmp[1] +
        projection.mat[8] * tmp[2] +
        projection.mat[12] * tmp[3];
    out[1] = projection.mat[1] * tmp[0] +
        projection.mat[5] * tmp[1] +
        projection.mat[9] * tmp[2] +
        projection.mat[13] * tmp[3];
    out[2] = projection.mat[2] * tmp[0] +
        projection.mat[6] * tmp[1] +
        projection.mat[10] * tmp[2] +
        projection.mat[14] * tmp[3];
    out[3] = projection.mat[3] * tmp[0] +
        projection.mat[7] * tmp[1] +
        projection.mat[11] * tmp[2] +
        projection.mat[15] * tmp[3];

    if (out[3] == 0.0) {
      return false;
    }

    out[0] /= out[3];
    out[1] /= out[3];
    out[2] /= out[3];

    out[0] = out[0] * 0.5 + 0.5;
    out[1] = out[1] * 0.5 + 0.5;
    out[2] = out[2] * 0.5 + 0.5;

    out[0] = out[0] * viewport[2] + viewport[0];
    out[1] = out[1] * viewport[3] + viewport[1];

    win[0] = out[0];
    win[1] = viewport[3] - out[1] - 1;
    win[2] = out[2];
    return true;
  }

  static bool unproject(
    List<double> win,
    OsMatrix modelView,
    OsMatrix projection,
    List<double> viewport,
    List<double> obj,
  ) {
    final OsMatrix finalMatrix = OsMatrix();
    finalMatrix.copyFrom(modelView);

    final List<double> tmp = [0.0, 0.0, 0.0, 0.0];
    final List<double> out = [0.0, 0.0, 0.0, 0.0];

    finalMatrix.preMultiply(projection);
    finalMatrix.invert();

    tmp[0] = viewport[0] + win[0];
    tmp[1] = viewport[1] + viewport[3] - win[1] - 1;
    tmp[2] = win[2];
    tmp[3] = 1.0;

    tmp[0] = (tmp[0] - viewport[0]) / viewport[2];
    tmp[1] = (tmp[1] - viewport[1]) / viewport[3];

    tmp[0] = tmp[0] * 2 - 1;
    tmp[1] = tmp[1] * 2 - 1;
    tmp[2] = tmp[2] * 2 - 1;

    out[0] = finalMatrix.mat[0] * tmp[0] +
        finalMatrix.mat[4] * tmp[1] +
        finalMatrix.mat[8] * tmp[2] +
        finalMatrix.mat[12] * tmp[3];
    out[1] = finalMatrix.mat[1] * tmp[0] +
        finalMatrix.mat[5] * tmp[1] +
        finalMatrix.mat[9] * tmp[2] +
        finalMatrix.mat[13] * tmp[3];
    out[2] = finalMatrix.mat[2] * tmp[0] +
        finalMatrix.mat[6] * tmp[1] +
        finalMatrix.mat[10] * tmp[2] +
        finalMatrix.mat[14] * tmp[3];
    out[3] = finalMatrix.mat[3] * tmp[0] +
        finalMatrix.mat[7] * tmp[1] +
        finalMatrix.mat[11] * tmp[2] +
        finalMatrix.mat[15] * tmp[3];

    if (out[3] == 0.0) {
      return false;
    }

    out[0] /= out[3];
    out[1] /= out[3];
    out[2] /= out[3];

    obj[0] = out[0];
    obj[1] = out[1];
    obj[2] = out[2];
    return true;
  }

  static void multiplyByMatrix(
    List<double> input,
    OsMatrix mat,
    List<double> output,
  ) {
    output[0] = mat.mat[0] * input[0] +
        mat.mat[4] * input[1] +
        mat.mat[8] * input[2] +
        mat.mat[12];
    output[1] = mat.mat[1] * input[0] +
        mat.mat[5] * input[1] +
        mat.mat[9] * input[2] +
        mat.mat[13];
    output[2] = mat.mat[2] * input[0] +
        mat.mat[6] * input[1] +
        mat.mat[10] * input[2] +
        mat.mat[14];
  }
}
