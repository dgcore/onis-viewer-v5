import 'dart:async';

class OsMessage {
  final int id;
  final dynamic data;

  OsMessage(this.id, this.data);
}

class OsMessageService {
  final StreamController<OsMessage?> _controller =
      StreamController<OsMessage?>.broadcast(sync: true);

  void sendMessage(int id, dynamic data) {
    _controller.add(OsMessage(id, data));
  }

  void clearMessage() {
    _controller.add(null);
  }

  Stream<OsMessage?> getMessage() {
    return _controller.stream;
  }

  void dispose() {
    _controller.close();
  }
}
