import 'package:flutter/material.dart';
import 'package:onis_viewer/core/graphics/container/container_wnd.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

abstract class IDownloadController extends ChangeNotifier {
  void registerContainer(OsContainerWnd container, bool reg);
  void setContainerPriority(OsContainerWnd container, bool hasPriority);
  void addSeriesToLoadingQueue(entities.Series series, bool force);
}
