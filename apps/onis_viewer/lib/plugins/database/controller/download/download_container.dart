import 'package:onis_viewer/core/graphics/container/container_wnd.dart';

class DownloadContainer {
  bool hasPriority = false;
  final WeakReference<OsContainerWnd>? _wcontainer;

  DownloadContainer(OsContainerWnd container)
      : _wcontainer = WeakReference<OsContainerWnd>(container);

  OsContainerWnd? get container => _wcontainer?.target;
}
