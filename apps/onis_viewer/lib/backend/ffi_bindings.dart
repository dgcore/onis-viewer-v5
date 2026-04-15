import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';

final class OnisBackendHandle extends ffi.Opaque {}

abstract final class OnisBackendStatus {
  static const int ok = 0;
  static const int error = 1;
  static const int invalidArgument = 2;
}

typedef _VersionNative = ffi.Int32 Function();
typedef _VersionDart = int Function();

typedef _CreateNative = ffi.Pointer<OnisBackendHandle> Function();
typedef _CreateDart = ffi.Pointer<OnisBackendHandle> Function();

typedef _DestroyNative = ffi.Void Function(ffi.Pointer<OnisBackendHandle>);
typedef _DestroyDart = void Function(ffi.Pointer<OnisBackendHandle>);

typedef _PingNative = ffi.Int32 Function(
  ffi.Pointer<OnisBackendHandle>,
  ffi.Int32,
  ffi.Pointer<ffi.Int32>,
);
typedef _PingDart = int Function(
  ffi.Pointer<OnisBackendHandle>,
  int,
  ffi.Pointer<ffi.Int32>,
);

typedef _GetLastErrorNative = ffi.Pointer<Utf8> Function();
typedef _GetLastErrorDart = ffi.Pointer<Utf8> Function();

typedef _InstanceIdNative = ffi.Int32 Function(ffi.Pointer<OnisBackendHandle>);
typedef _InstanceIdDart = int Function(ffi.Pointer<OnisBackendHandle>);

class OnisBackendBindings {
  OnisBackendBindings(ffi.DynamicLibrary lib)
      : version = lib.lookupFunction<_VersionNative, _VersionDart>(
          'onis_backend_version',
        ),
        create = lib.lookupFunction<_CreateNative, _CreateDart>(
          'onis_backend_create',
        ),
        destroy = lib.lookupFunction<_DestroyNative, _DestroyDart>(
          'onis_backend_destroy',
        ),
        ping = lib.lookupFunction<_PingNative, _PingDart>(
          'onis_backend_ping',
        ),
        instanceId = lib.lookupFunction<_InstanceIdNative, _InstanceIdDart>(
          'onis_backend_instance_id',
        ),
        getLastError = lib.lookupFunction<_GetLastErrorNative, _GetLastErrorDart>(
          'onis_backend_get_last_error',
        );

  final _VersionDart version;
  final _CreateDart create;
  final _DestroyDart destroy;
  final _PingDart ping;
  final _InstanceIdDart instanceId;
  final _GetLastErrorDart getLastError;
}
