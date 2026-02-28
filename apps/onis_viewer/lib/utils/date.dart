/// Utility functions for date and time manipulation
library;

/// Creates a DateTime object from DICOM-style date and time strings.
///
/// [dateStr] - Date string in YYYYMMDD format (e.g., "20231225")
/// [timeStr] - Optional time string in HHMMSS.XXX format (e.g., "143025.123")
///             The milliseconds part (.XXX) is optional.
///             If [timeStr] is null, empty, or blank, the DateTime will
///             only contain date information (time set to 00:00:00.000).
///
/// Returns a DateTime object in UTC, or null if parsing fails.
///
/// Example:
/// ```dart
/// // Date only
/// final date1 = createDateTimeFromDicom("20231225", null);
/// // DateTime(2023, 12, 25, 0, 0, 0, 0)
///
/// // Date and time without milliseconds
/// final date2 = createDateTimeFromDicom("20231225", "143025");
/// // DateTime(2023, 12, 25, 14, 30, 25, 0)
///
/// // Date and time with milliseconds
/// final date3 = createDateTimeFromDicom("20231225", "143025.123");
/// // DateTime(2023, 12, 25, 14, 30, 25, 123)
/// ```
DateTime? createDateTimeFromDicom(String dateStr, String? timeStr) {
  // Validate and parse date string (YYYYMMDD)
  if (dateStr.length != 8) {
    return null;
  }

  try {
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));

    // Validate date components
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    // Parse time string if provided and not blank
    int hour = 0;
    int minute = 0;
    int second = 0;
    int millisecond = 0;

    if (timeStr != null && timeStr.trim().isNotEmpty) {
      // Remove any whitespace
      final trimmedTime = timeStr.trim();

      // Minimum length is 6 (HHMMSS)
      if (trimmedTime.length < 6) {
        return null;
      }

      // Parse hours, minutes, seconds
      hour = int.parse(trimmedTime.substring(0, 2));
      minute = int.parse(trimmedTime.substring(2, 4));
      second = int.parse(trimmedTime.substring(4, 6));

      // Validate time components
      if (hour > 23 || minute > 59 || second > 59) {
        return null;
      }

      // Parse milliseconds if present (format: .XXX)
      if (trimmedTime.length > 6) {
        if (trimmedTime[6] == '.') {
          final millisecondStr = trimmedTime.substring(7);
          if (millisecondStr.isNotEmpty) {
            // Pad or truncate to 3 digits
            final paddedMs = millisecondStr.padRight(3, '0').substring(0, 3);
            millisecond = int.parse(paddedMs);
          }
        }
      }
    }

    // Create DateTime in UTC to avoid timezone issues
    return DateTime.utc(year, month, day, hour, minute, second, millisecond);
  } catch (e) {
    // Return null if any parsing fails
    return null;
  }
}
