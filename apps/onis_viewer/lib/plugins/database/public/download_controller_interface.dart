import 'package:flutter/material.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;

abstract class IDownloadController extends ChangeNotifier {
  void addSeriesToLoadingQueue(entities.Series series, bool force);
}
