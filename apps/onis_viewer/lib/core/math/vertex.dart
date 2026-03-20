class OsVertex3d {
  List<double> pos = [0.0, 0.0, 0.0];
  List<double> norm = [0.0, 0.0, 0.0];
  List<double> tex = [0.0, 0.0];

  OsVertex3d();

  OsVertex3d.withValues(
    double x,
    double y,
    double z,
    double nx,
    double ny,
    double nz,
    double tu,
    double tv,
  ) {
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;

    norm[0] = nx;
    norm[1] = ny;
    norm[2] = nz;

    tex[0] = tu;
    tex[1] = tv;
  }

  void setData(
    double x,
    double y,
    double z,
    double nx,
    double ny,
    double nz,
    double tu,
    double tv,
  ) {
    pos[0] = x;
    pos[1] = y;
    pos[2] = z;

    norm[0] = nx;
    norm[1] = ny;
    norm[2] = nz;

    tex[0] = tu;
    tex[1] = tv;
  }
}
