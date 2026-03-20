import 'dart:math' as math;

class OsVec2D {
  static bool lineIntersection(
    List<double> pt1,
    List<double> vec1,
    List<double> pt2,
    List<double> vec2,
    List<double> output,
  ) {
    final double a = vec1[0];
    final double b = vec2[0];
    final double c = vec1[1];
    final double d = vec2[1];
    final double e = pt2[0] - pt1[0];
    final double f = pt2[1] - pt1[1];

    if ((a * d - b * c).abs() < 0.0001) {
      return false;
    }

    final double k = (d * e - b * f) / (a * d - b * c);
    output[0] = pt1[0] + k * vec1[0];
    output[1] = pt1[1] + k * vec1[1];
    return true;
  }

  // Return value:
  //  0: no point is inside, but the line intersects the rectangle
  //  1: first point is inside
  //  2: second point is inside
  //  3: both points are inside
  // -1: no point is inside and no edge is intersected
  static int squareIntersection(
    List<double> corner,
    List<double> oppositeCorner,
    List<double> from,
    List<double> to,
    bool testEdge,
  ) {
    final List<double> lb = [0.0, 0.0];
    final List<double> rt = [0.0, 0.0];

    lb[0] = (corner[0] < oppositeCorner[0]) ? corner[0] : oppositeCorner[0];
    rt[0] = (corner[0] < oppositeCorner[0]) ? oppositeCorner[0] : corner[0];
    lb[1] = (corner[1] < oppositeCorner[1]) ? corner[1] : oppositeCorner[1];
    rt[1] = (corner[1] < oppositeCorner[1]) ? oppositeCorner[1] : corner[1];

    int ret = 0;

    if ((from[0] >= lb[0]) && (from[0] <= rt[0])) {
      if ((from[1] >= lb[1]) && (from[1] <= rt[1])) {
        ret += 1;
      }
    }

    if ((to[0] >= lb[0]) && (to[0] <= rt[0])) {
      if ((to[1] >= lb[1]) && (to[1] <= rt[1])) {
        ret += 2;
      }
    }

    if (ret == 0) {
      ret = -1;
    }

    if (!testEdge) {
      return ret;
    }

    if ((from[0] - to[0]).abs() < 0.0001) {
      if ((to[1] - from[1]).abs() > 0.0001) {
        double x = from[0];
        double y = lb[1];
        if ((x >= lb[0]) && (x <= rt[0])) {
          final double k = (y - from[1]) / (to[1] - from[1]);
          if ((k >= 0) && (k <= 1)) {
            return (ret == -1) ? 0 : ret;
          }
        }

        x = from[0];
        y = rt[1];
        if ((x >= lb[0]) && (x <= rt[0])) {
          final double k = (y - from[1]) / (to[1] - from[1]);
          if ((k >= 0) && (k <= 1)) {
            return (ret == -1) ? 0 : ret;
          }
        }
      }
    } else {
      final double a = (to[1] - from[1]) / (to[0] - from[0]);
      final double b = from[1] - a * from[0];
      double x;
      double y;

      if (a != 0) {
        x = (lb[1] - b) / a;
        y = lb[1];
        if ((x >= lb[0]) && (x <= rt[0])) {
          final double k = (x - from[0]) / (to[0] - from[0]);
          if ((k >= 0) && (k <= 1)) {
            return (ret == -1) ? 0 : ret;
          }
        }
      }

      if (a != 0) {
        x = (rt[1] - b) / a;
        y = rt[1];
        if ((x >= lb[0]) && (x <= rt[0])) {
          final double k = (x - from[0]) / (to[0] - from[0]);
          if ((k >= 0) && (k <= 1)) {
            return (ret == -1) ? 0 : ret;
          }
        }
      }

      x = lb[0];
      y = a * lb[0] + b;
      if ((y >= lb[1]) && (y <= rt[1])) {
        final double k = (x - from[0]) / (to[0] - from[0]);
        if ((k >= 0) && (k <= 1)) {
          return (ret == -1) ? 0 : ret;
        }
      }

      x = rt[0];
      y = a * rt[0] + b;
      if ((y >= lb[1]) && (y <= rt[1])) {
        final double k = (x - from[0]) / (to[0] - from[0]);
        if ((k >= 0) && (k <= 1)) {
          return (ret == -1) ? 0 : ret;
        }
      }
    }

    return ret;
  }

  static double getVectorLength(List<double> vec) {
    final double length = vec[0] * vec[0] + vec[1] * vec[1];
    return math.sqrt(length);
  }

  static double getLength(List<double> pt1, List<double> pt2) {
    final double length = (pt2[0] - pt1[0]) * (pt2[0] - pt1[0]) +
        (pt2[1] - pt1[1]) * (pt2[1] - pt1[1]);
    return math.sqrt(length);
  }

  static double normalize(List<double> vec) {
    final double length = math.sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
    if (length != 0) {
      vec[0] /= length;
      vec[1] /= length;
    }
    return length;
  }

  static double scalarProduct(List<double> vec1, List<double> vec2) {
    return vec1[0] * vec2[0] + vec1[1] * vec2[1];
  }

  static bool getKFactor(
    List<double> pt1,
    List<double> pt2,
    List<double> pt3,
    List<double> k,
  ) {
    final double x = (pt2[0] - pt1[0]).abs();
    final double y = (pt2[1] - pt1[1]).abs();

    if (x > y) {
      if (x < 0.0001) {
        return false;
      }
      k[0] = (pt3[0] - pt1[0]) / (pt2[0] - pt1[0]);
    } else {
      if (y < 0.0001) {
        return false;
      }
      k[0] = (pt3[1] - pt1[1]) / (pt2[1] - pt1[1]);
    }
    return true;
  }

  static void adjustKFactor(List<double> k) {
    final double val = k[0];
    final double dabs = val.abs();

    if (val.abs() < 0.001) {
      k[0] = 0.0;
    } else if (val > 0) {
      if ((dabs - 1.0).abs() < 0.001) {
        k[0] = 1.0;
      }
    }
  }
}
