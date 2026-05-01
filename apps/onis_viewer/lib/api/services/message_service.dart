import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';

typedef OsMessageListener = void Function(int id, dynamic data);

class OsMessageService {
  OsMessageService() {
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (call.method == windowMethodName) {
        final args = call.arguments;
        if (args is! Map) {
          return null;
        }
        final rawId = args['msgId'];
        final id = rawId is int ? rawId : (rawId is num ? rawId.toInt() : null);
        if (id == null) {
          return null;
        }
        final payload = args['payload'];
        dynamic data;
        final bytes = _payloadAsUint8List(payload);
        if (bytes != null) {
          data = bytes.isEmpty ? null : _decodePayload(bytes);
        } else {
          data = payload;
        }
        _dispatchLocal(id, data);
      }
      return null;
    });
  }

  static const String windowMethodName = 'onis/os_message';
  final Map<int, OsMessageListener> _listeners = {};
  int _nextId = 0;

  int subscribe(OsMessageListener listener) {
    final id = _nextId++;
    _listeners[id] = listener;
    return id;
  }

  void unsubscribe(int id) {
    _listeners.remove(id);
  }

  Future<void> sendMessage(int id, dynamic data) async {
    _dispatchLocal(id, data);
    await _deliverToOtherWindows(id, data);
  }

  void _dispatchLocal(int id, dynamic data) {
    for (final listener in List<OsMessageListener>.from(_listeners.values)) {
      listener(id, data);
    }
  }

  Future<void> _deliverToOtherWindows(int id, dynamic data) async {
    if (kIsWeb) {
      return;
    }
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    final targets = await _targetPeerWindowIds();
    if (targets.isEmpty) {
      return;
    }

    Uint8List payload;
    try {
      payload = _encodePayload(data);
    } catch (e, st) {
      debugPrint('OsMessageService: payload encode failed: $e\n$st');
      return;
    }

    final args = <String, dynamic>{'msgId': id, 'payload': payload};
    for (final targetId in targets) {
      try {
        await DesktopMultiWindow.invokeMethod(
          targetId,
          windowMethodName,
          args,
        );
      } catch (e, st) {
        debugPrint(
          'OsMessageService: invokeMethod to window $targetId failed: $e\n$st',
        );
      }
    }
  }

  /// Main window id is always `0` (see `WindowController.main`).
  Future<List<int>> _targetPeerWindowIds() async {
    final subs = await DesktopMultiWindow.getAllSubWindowIds();
    const mainId = 0;

    final ownId = OVApi().flutterEngineInstanceId;
    if (ownId == mainId) {
      return subs;
    }

    final out = <int>[mainId];
    for (final sid in subs) {
      if (sid != ownId) {
        out.add(sid);
      }
    }
    return out;
  }

  Uint8List _encodePayload(dynamic data) {
    final w = WriteBuffer();
    const StandardMessageCodec().writeValue(w, data);
    final bd = w.done();
    return Uint8List.view(
      bd.buffer,
      bd.offsetInBytes,
      bd.lengthInBytes,
    );
  }

  dynamic _decodePayload(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final reader = ReadBuffer(bd);
    return const StandardMessageCodec().readValue(reader);
  }

  /// Normalizes channel payload (e.g. [Uint8List], view types, [List<int>]).
  Uint8List? _payloadAsUint8List(dynamic payload) {
    if (payload == null) {
      return null;
    }
    if (payload is Uint8List) {
      return payload;
    }
    if (payload is ByteData) {
      return Uint8List.view(
        payload.buffer,
        payload.offsetInBytes,
        payload.lengthInBytes,
      );
    }
    if (payload is List<int>) {
      return Uint8List.fromList(payload);
    }
    return null;
  }

  void dispose() {
    _listeners.clear();
  }
}
