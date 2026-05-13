import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// One decoded item from the site-server binary download stream (`ONISDL01` …).
class OnisDlStreamItem {
  OnisDlStreamItem({
    required this.downloadSeq,
    required this.loadIndex,
    required this.itemType,
    required this.resultCode,
    required this.fileBytes,
    required this.tempFilePath,
  });

  final String downloadSeq;
  final int loadIndex;
  final int itemType;
  final int resultCode;

  /// Raw Part 10 bytes when the payload was small enough to buffer in memory.
  final Uint8List? fileBytes;

  /// Temp path when the payload was spilled to disk (large files).
  final String? tempFilePath;
}

/// Parses the ONIS site-server streaming download format incrementally.
///
/// Wire layout (little-endian):
/// - magic: 8 bytes `ONISDL01`
/// - `u32` series_count
/// - per series: `u32` seq_len, seq utf8, `u32` completed, `u32` expected
/// - `u32` item_count
/// - per item: `u32` dl_len, dl utf8, `u32` index, `u32` type, `u32` result,
///   `u64` file_size, `file_size` raw bytes
class OnisDownloadStreamParser {
  OnisDownloadStreamParser({
    required this.onItem,
    required this.memoryThresholdBytes,
  });

  final void Function(OnisDlStreamItem item) onItem;
  final int memoryThresholdBytes;

  Uint8List _buf = Uint8List(0);

  _Phase _phase = _Phase.magic;

  int _seriesCount = 0;
  int _seriesIndex = 0;
  int _seriesSeqLen = 0;

  int _itemCount = 0;
  int _itemIndex = 0;

  int _dlLen = 0;
  String _downloadSeq = '';

  int _loadIndex = 0;
  int _itemType = 0;
  int _resultCode = 0;
  int _fileSize = 0;

  int _payloadRemaining = 0;
  BytesBuilder? _payloadMem;
  RandomAccessFile? _payloadFile;
  String? _payloadPath;

  bool _failed = false;

  /// True after [end] if the stream ended early or failed validation.
  bool get failed => _failed;

  void feed(Uint8List chunk) {
    if (_failed || chunk.isEmpty) return;
    _append(chunk);
    _run();
  }

  /// Call when the HTTP stream ended; reports trailing garbage as failure.
  void end() {
    if (_failed) return;
    if (_buf.isNotEmpty || _phase != _Phase.done) {
      debugPrint(
        'OnisDownloadStreamParser: incomplete stream phase=$_phase pending=${_buf.length}',
      );
      _failed = true;
    }
    _resetPayloadWriters();
  }

  void _append(Uint8List chunk) {
    if (_buf.isEmpty) {
      _buf = chunk;
    } else {
      final merged = Uint8List(_buf.length + chunk.length);
      merged.setAll(0, _buf);
      merged.setAll(_buf.length, chunk);
      _buf = merged;
    }
  }

  void _consume(int n) {
    _buf = _buf.sublist(n);
  }

  void _run() {
    while (!_failed && _buf.isNotEmpty) {
      switch (_phase) {
        case _Phase.magic:
          if (_buf.length < 8) return;
          if (!_checkMagic()) {
            _fail('bad magic');
            return;
          }
          _consume(8);
          _phase = _Phase.seriesCount;
          break;

        case _Phase.seriesCount:
          if (_buf.length < 4) return;
          _seriesCount = _readU32(0);
          _consume(4);
          _seriesIndex = 0;
          _phase =
              _seriesCount == 0 ? _Phase.itemCount : _Phase.seriesSeqLen;
          break;

        case _Phase.seriesSeqLen:
          if (_buf.length < 4) return;
          _seriesSeqLen = _readU32(0);
          _consume(4);
          _phase = _Phase.seriesSeq;
          break;

        case _Phase.seriesSeq:
          if (_buf.length < _seriesSeqLen) return;
          _consume(_seriesSeqLen);
          _phase = _Phase.seriesCompleted;
          break;

        case _Phase.seriesCompleted:
          if (_buf.length < 4) return;
          _consume(4);
          _phase = _Phase.seriesExpected;
          break;

        case _Phase.seriesExpected:
          if (_buf.length < 4) return;
          _consume(4);
          _seriesIndex++;
          _phase = _seriesIndex >= _seriesCount
              ? _Phase.itemCount
              : _Phase.seriesSeqLen;
          break;

        case _Phase.itemCount:
          if (_buf.length < 4) return;
          _itemCount = _readU32(0);
          _consume(4);
          _itemIndex = 0;
          _phase =
              _itemCount == 0 ? _Phase.done : _Phase.itemDlLen;
          break;

        case _Phase.itemDlLen:
          if (_buf.length < 4) return;
          _dlLen = _readU32(0);
          _consume(4);
          _downloadSeq = '';
          _phase = _Phase.itemDl;
          break;

        case _Phase.itemDl:
          if (_buf.length < _dlLen) return;
          _downloadSeq = utf8.decode(_buf.sublist(0, _dlLen));
          _consume(_dlLen);
          _phase = _Phase.itemIndex;
          break;

        case _Phase.itemIndex:
          if (_buf.length < 4) return;
          _loadIndex = _readU32(0);
          _consume(4);
          _phase = _Phase.itemType;
          break;

        case _Phase.itemType:
          if (_buf.length < 4) return;
          _itemType = _readU32(0);
          _consume(4);
          _phase = _Phase.itemResult;
          break;

        case _Phase.itemResult:
          if (_buf.length < 4) return;
          _resultCode = _readU32(0);
          _consume(4);
          _phase = _Phase.itemFileSize;
          break;

        case _Phase.itemFileSize:
          if (_buf.length < 8) return;
          _fileSize = _readU64(0);
          _consume(8);
          _payloadRemaining = _fileSize;
          _resetPayloadWriters();
          if (_fileSize == 0) {
            _emitItem();
            _advanceItem();
          } else {
            _startPayloadStorage();
            _phase = _Phase.itemPayload;
          }
          break;

        case _Phase.itemPayload:
          final take = _payloadRemaining < _buf.length
              ? _payloadRemaining
              : _buf.length;
          if (take == 0) return;
          final slice = _buf.sublist(0, take);
          _writePayloadSlice(slice);
          _consume(take);
          _payloadRemaining -= take;
          if (_payloadRemaining == 0) {
            _finishPayloadStorage();
            _emitItem();
            _advanceItem();
          }
          break;

        case _Phase.done:
          return;
      }
    }
  }

  bool _checkMagic() {
    const expected = [79, 78, 73, 83, 68, 76, 48, 49]; // ONISDL01
    for (var i = 0; i < 8; i++) {
      if (_buf[i] != expected[i]) return false;
    }
    return true;
  }

  int _readU32(int offset) {
    var x = 0;
    for (var i = 0; i < 4; i++) {
      x |= (_buf[offset + i] & 0xff) << (8 * i);
    }
    return x;
  }

  int _readU64(int offset) {
    var x = 0;
    for (var i = 0; i < 8; i++) {
      x |= (_buf[offset + i] & 0xff) << (8 * i);
    }
    return x;
  }

  void _startPayloadStorage() {
    if (_fileSize <= memoryThresholdBytes) {
      _payloadMem = BytesBuilder(copy: false);
    } else {
      _payloadPath =
          '${Directory.systemTemp.path}/onis_dl_${DateTime.now().microsecondsSinceEpoch}_${_itemIndex}.part';
      final f = File(_payloadPath!);
      _payloadFile = f.openSync(mode: FileMode.write);
    }
  }

  void _writePayloadSlice(Uint8List slice) {
    if (_payloadMem != null) {
      _payloadMem!.add(slice);
    } else {
      _payloadFile!.writeFromSync(slice);
    }
  }

  void _finishPayloadStorage() {
    _payloadFile?.closeSync();
    _payloadFile = null;
  }

  void _resetPayloadWriters() {
    _payloadMem = null;
    _payloadFile?.closeSync();
    _payloadFile = null;
    _payloadPath = null;
  }

  void _emitItem() {
    Uint8List? bytes;
    String? path;
    if (_fileSize > 0) {
      if (_payloadMem != null) {
        bytes = _payloadMem!.takeBytes();
        _payloadMem = null;
      } else {
        path = _payloadPath;
      }
    }
    _resetPayloadWriters();

    onItem(OnisDlStreamItem(
      downloadSeq: _downloadSeq,
      loadIndex: _loadIndex,
      itemType: _itemType,
      resultCode: _resultCode,
      fileBytes: bytes,
      tempFilePath: path,
    ));
  }

  void _advanceItem() {
    _itemIndex++;
    if (_itemIndex >= _itemCount) {
      _phase = _Phase.done;
    } else {
      _phase = _Phase.itemDlLen;
    }
  }

  void _fail(String msg) {
    debugPrint('OnisDownloadStreamParser: $msg');
    _failed = true;
    _resetPayloadWriters();
  }
}

enum _Phase {
  magic,
  seriesCount,
  seriesSeqLen,
  seriesSeq,
  seriesCompleted,
  seriesExpected,
  itemCount,
  itemDlLen,
  itemDl,
  itemIndex,
  itemType,
  itemResult,
  itemFileSize,
  itemPayload,
  done,
}
