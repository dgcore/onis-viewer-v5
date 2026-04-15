import 'package:onis_viewer/core/manager/base_manager.dart';

abstract class HasId {
  String getId();
}

class SimpleManager<T extends HasId> extends BaseManager {
  final List<T> _list = [];

  SimpleManager(
    super.id, [
    super.registerMsg = 0,
    super.unregisterMsg = 0,
  ]);

  bool registerItem(T element, bool reg) {
    if (reg) {
      if (find(element.getId()) != null) {
        return false;
      }
      _list.add(element);
      if (registerMsg != 0) {
        presendMessage(registerMsg, element);
        sendMessage(registerMsg, element);
      }
      return true;
    } else {
      final index = _list.indexOf(element);
      if (index == -1) {
        return false;
      }
      final removed = _list[index];
      _list.removeAt(index);
      if (unregisterMsg != 0) {
        presendMessage(unregisterMsg, removed);
        sendMessage(unregisterMsg, removed);
      }
      return true;
    }
  }

  List<T> getList() {
    return _list;
  }

  T? find(String id) {
    for (final item in _list) {
      if (item.getId() == id) {
        return item;
      }
    }
    return null;
  }

  void presendMessage(int message, T element) {}

  void dispose() {
    while (_list.isNotEmpty) {
      final element = _list.first;
      if (unregisterMsg != 0) {
        presendMessage(unregisterMsg, element);
        sendMessage(unregisterMsg, element);
      }
      _list.removeAt(0);
    }
  }
}
