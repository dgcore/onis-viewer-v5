import 'package:onis_viewer/api/graphics/renderers/renderer_2d.dart';
import 'package:onis_viewer/core/graphics/renderer/renderer.dart';

class OsRenderTypeManager {
  final List<OsRendererType> _rendererTypes = [];

  OsRenderTypeManager();

  void initialize() {
    register(OsRenderer2DType());
  }

  void register(OsRendererType rendererType) {
    if (!_rendererTypes.contains(rendererType)) {
      _rendererTypes.add(rendererType);
    }
  }

  void unregister(OsRendererType rendererType) {
    if (_rendererTypes.contains(rendererType)) {
      _rendererTypes.remove(rendererType);
    }
  }

  OsRendererType? get(String id) {
    final index = _rendererTypes.indexWhere((r) => r.id == id);
    return index >= 0 ? _rendererTypes[index] : null;
  }
}
