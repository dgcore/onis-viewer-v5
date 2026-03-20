import 'package:onis_viewer/core/error_codes.dart';

enum ResultStatus {
  success,
  failure,
  refused,
  warning,
  canceled,
  pending,
  pendingWarning,
  pendingOperation,
  waiting,
}

class OsResult {
  ResultStatus status;
  int reason;
  String info = '';

  OsResult(
      {this.status = ResultStatus.success,
      this.reason = OnisErrorCodes.none,
      this.info = ''});

  void reset() {
    status = ResultStatus.success;
    reason = OnisErrorCodes.none;
    info = '';
  }

  void setStatus(ResultStatus status, int reason, String info) {
    this.status = status;
    this.reason = reason;
    this.info = info;
  }

  bool isSuccess() {
    return status == ResultStatus.success;
  }
}
