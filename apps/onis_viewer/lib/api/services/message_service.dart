import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onis_viewer/api/services/message_codes.dart';

typedef OsMessageListener = void Function(int id, dynamic data);

class OsMessageService {
  OsMessageService({
    required int ownWindowId,
    required bool isSubWindowEngine,
  })  : _ownWindowId = ownWindowId,
        _isSubWindowEngine = isSubWindowEngine {
    DesktopMultiWindow.setMethodHandler(_onWindowMethodCall);
  }

  static const String windowMethodName = 'onis/os_message';
  static const String senderWindowIdKey = 'onisSenderWindowId';
  static const int mainWindowId = 0;

  /// Commands that must run on the main window (download / sources).
  static const Set<int> _mainWindowOnlyMessageIds = {
    OSMSG.cmdDownloadSeries,
  };

  final int _ownWindowId;
  final bool _isSubWindowEngine;
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
    final targets = await _targetPeerWindowIds();
    final skipLocal =
        _isSubWindowEngine && _mainWindowOnlyMessageIds.contains(id);

    if (kDebugMode) {
      debugPrint(
        'OsMessageService: send msg=$id ownWindow=$_ownWindowId '
        'targets=$targets skipLocal=$skipLocal',
      );
    }

    if (!skipLocal) {
      _dispatchLocal(id, data);
    }

    if (targets.isEmpty) {
      return;
    }

    await _deliverToTargets(targets, id, data);
  }

  Future<dynamic> _onWindowMethodCall(MethodCall call, int fromWindowId) async {
    if (call.method != windowMethodName) {
      return null;
    }

    final args = call.arguments;
    if (args is! Map) {
      return null;
    }

    final rawId = args['msgId'];
    final id = rawId is int ? rawId : (rawId is num ? rawId.toInt() : null);
    if (id == null) {
      return null;
    }

    final senderWindowId = (args[senderWindowIdKey] as num?)?.toInt();

    // Mis-routed invokeMethod(0) can bounce back to the sender isolate with
    // fromWindowId == 0 (target id) instead of reaching the main engine.
    if (senderWindowId != null && senderWindowId == _ownWindowId) {
      if (kDebugMode) {
        debugPrint(
          'OsMessageService: ignore loopback msg=$id '
          'ownWindow=$_ownWindowId platformFrom=$fromWindowId',
        );
      }
      return null;
    }

    final effectiveFrom = senderWindowId ?? fromWindowId;
    if (kDebugMode) {
      debugPrint(
        'OsMessageService: recv msg=$id ownWindow=$_ownWindowId '
        'from=$effectiveFrom (platformFrom=$fromWindowId)',
      );
    }

    dynamic data;
    final payload = args['payload'];
    final bytes = _payloadAsUint8List(payload);
    if (bytes != null) {
      data = bytes.isEmpty ? null : _decodePayload(bytes);
    } else {
      data = payload;
    }

    _dispatchLocal(id, data);
    return null;
  }

  void _dispatchLocal(int id, dynamic data) {
    for (final listener in List<OsMessageListener>.from(_listeners.values)) {
      listener(id, data);
    }
  }

  Future<void> _deliverToTargets(
    List<int> targets,
    int id,
    dynamic data,
  ) async {
    if (kIsWeb) {
      return;
    }
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    Uint8List payload;
    try {
      payload = _encodePayload(data);
    } catch (e, st) {
      debugPrint('OsMessageService: payload encode failed: $e\n$st');
      return;
    }

    final args = <String, dynamic>{
      'msgId': id,
      'payload': payload,
      senderWindowIdKey: _ownWindowId,
    };

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

  Future<List<int>> _targetPeerWindowIds() async {
    final subs = await DesktopMultiWindow.getAllSubWindowIds();

    if (!_isSubWindowEngine && _ownWindowId == mainWindowId) {
      return subs;
    }

    return [
      mainWindowId,
      for (final sid in subs)
        if (sid != _ownWindowId) sid,
    ];
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
