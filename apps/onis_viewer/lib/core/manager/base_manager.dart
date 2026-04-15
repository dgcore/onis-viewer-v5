import 'package:onis_viewer/api/core/ov_api_core.dart';

abstract class BaseManager {
  final int registerMsg;
  final int unregisterMsg;
  final String _id;

  BaseManager(
    this._id,
    this.registerMsg,
    this.unregisterMsg,
  );

  String get id {
    return _id;
  }

  void sendMessage(int id, dynamic data) {
    OVApi().messages.sendMessage(id, data);
  }
}
