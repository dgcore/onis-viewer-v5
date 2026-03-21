class DateUtils {
  /// Parse une date DICOM (YYYYMMDD) et une heure DICOM optionnelle
  /// (HHMMSS, HHMMSS.F, HHMMSS.FF, HHMMSS.FFF, etc.).
  ///
  /// Retourne null si le format est invalide.
  static DateTime? createDateTimeFromDicom(String dateStr, String? timeStr) {
    if (dateStr.length != 8) {
      return null;
    }

    final int year;
    final int month;
    final int day;

    try {
      year = int.parse(dateStr.substring(0, 4));
      month = int.parse(dateStr.substring(4, 6));
      day = int.parse(dateStr.substring(6, 8));
    } catch (_) {
      return null;
    }

    int hour = 0;
    int minute = 0;
    int second = 0;
    int millisecond = 0;

    final String trimmedTime = timeStr?.trim() ?? '';
    if (trimmedTime.isNotEmpty) {
      if (trimmedTime.length < 6) {
        return null;
      }

      try {
        hour = int.parse(trimmedTime.substring(0, 2));
        minute = int.parse(trimmedTime.substring(2, 4));
        second = int.parse(trimmedTime.substring(4, 6));
      } catch (_) {
        return null;
      }

      if (hour > 23 || minute > 59 || second > 59) {
        return null;
      }

      if (trimmedTime.length > 6) {
        if (trimmedTime[6] != '.') {
          return null;
        }

        final String fraction = trimmedTime.substring(7);
        if (fraction.isEmpty) {
          return null;
        }

        if (!RegExp(r'^\d+$').hasMatch(fraction)) {
          return null;
        }

        final String msText = fraction.padRight(3, '0').substring(0, 3);

        try {
          millisecond = int.parse(msText);
        } catch (_) {
          return null;
        }
      }
    }

    final DateTime dt = DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );

    if (dt.year != year ||
        dt.month != month ||
        dt.day != day ||
        dt.hour != hour ||
        dt.minute != minute ||
        dt.second != second ||
        dt.millisecond != millisecond) {
      return null;
    }

    return dt;
  }

  static DateTime? parseDicomDate(String dateStr) {
    return createDateTimeFromDicom(dateStr, null);
  }
}
