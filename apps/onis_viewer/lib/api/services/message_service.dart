import 'dart:async';

class OsMessage {
  final int id;
  final dynamic data;

  OsMessage(this.id, this.data);
}

typedef OsMessageListener = void Function(OsMessage? message);

class OsMessageSubscription {
  final OsMessageService _service;
  final int _id;
  bool _cancelled = false;

  OsMessageSubscription._(this._service, this._id);

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _service._unsubscribe(_id);
  }
}

/// Synchronous message dispatcher.
///
/// This intentionally does NOT rely on StreamController(sync: true) because
/// nested sendMessage() calls from inside listeners can throw:
/// "Cannot fire new event. Controller is already firing an event".
class OsMessageService {
  final Map<int, OsMessageListener> _listeners = {};
  int _nextId = 0;

  // Optional async stream (kept for backward compatibility / debugging).
  // Primary synchronous semantics come from subscribe()/sendMessage().
  final StreamController<OsMessage?> _streamController =
      StreamController<OsMessage?>.broadcast();

  OsMessageSubscription subscribe(OsMessageListener listener) {
    final id = _nextId++;
    _listeners[id] = listener;
    return OsMessageSubscription._(this, id);
  }

  void _unsubscribe(int id) {
    _listeners.remove(id);
  }

  void sendMessage(int id, dynamic data) {
    final message = OsMessage(id, data);
    _dispatch(message);
  }

  void clearMessage() {
    _dispatch(null);
  }

  void _dispatch(OsMessage? message) {
    // Snapshot to tolerate subscribe/unsubscribe while dispatching.
    final snapshot = List<OsMessageListener>.from(_listeners.values);
    for (final listener in snapshot) {
      listener(message);
    }
    _streamController.add(message);
  }

  Stream<OsMessage?> getMessage() => _streamController.stream;

  void dispose() {
    _listeners.clear();
    _streamController.close();
  }
}
