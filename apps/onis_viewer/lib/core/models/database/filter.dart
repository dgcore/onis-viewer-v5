/// Filter value with type information
class FilterValue {
  dynamic value;
  int type;

  FilterValue({this.value = '', this.type = 0});
}

/// Database filters for study search
class DBFilters {
  // Date mode constants
  static const int any = -1;
  static const int today = 0;
  static const int yesterday = 1;
  static const int thisWeek = 2;
  static const int lastWeek = 3;
  static const int last7Days = 4;
  static const int last14Days = 5;
  static const int last21Days = 6;
  static const int thisMonth = 7;
  static const int lastMonth = 8;
  static const int last30Days = 9;
  static const int last60Days = 10;
  static const int last90Days = 11;
  static const int thisYear = 12;
  static const int custom = 13;

  // Filter properties
  FilterValue pid = FilterValue(value: '', type: 1);
  FilterValue name = FilterValue(value: '', type: 1);
  FilterValue sex = FilterValue(value: '', type: 0);
  FilterValue parts = FilterValue(value: '', type: 1);
  FilterValue accnum = FilterValue(value: '', type: 0);
  FilterValue studyid = FilterValue(value: '', type: 0);
  FilterValue desc = FilterValue(value: '', type: 0);
  FilterValue comment = FilterValue(value: '', type: 0);
  FilterValue institution = FilterValue(value: '', type: 1);
  FilterValue modalities = FilterValue(value: '', type: 1);
  FilterValue stations = FilterValue(value: '', type: 1);
  FilterValue status = FilterValue(value: 0, type: 0);
  FilterValue startStudyDate = FilterValue(value: '', type: 0);
  FilterValue endStudyDate = FilterValue(value: '', type: 0);
  FilterValue studyDateMode = FilterValue(value: 0, type: 0);

  DBFilters();

  /// Copy all filter values to another DBFilters instance
  void copyTo(DBFilters f) {
    f.pid.value = pid.value;
    f.pid.type = pid.type;

    f.name.value = name.value;
    f.name.type = name.type;

    f.sex.value = sex.value;
    f.sex.type = sex.type;

    f.parts.value = parts.value;
    f.parts.type = parts.type;

    f.accnum.value = accnum.value;
    f.accnum.type = accnum.type;

    f.studyid.value = studyid.value;
    f.studyid.type = studyid.type;

    f.desc.value = desc.value;
    f.desc.type = desc.type;

    f.comment.value = comment.value;
    f.comment.type = comment.type;

    f.modalities.value = modalities.value;
    f.modalities.type = modalities.type;

    f.institution.value = institution.value;
    f.institution.type = institution.type;

    f.stations.value = stations.value;
    f.stations.type = stations.type;

    f.status.value = status.value;
    f.status.type = status.type;

    f.startStudyDate.value = startStudyDate.value;
    f.startStudyDate.type = startStudyDate.type;

    f.endStudyDate.value = endStudyDate.value;
    f.endStudyDate.type = endStudyDate.type;

    f.studyDateMode.value = studyDateMode.value;
    f.studyDateMode.type = studyDateMode.type;
  }

  /// Check if this filter is equal to another filter
  bool isEqual(DBFilters f) {
    if (pid.value != f.pid.value) return false;
    if (name.value != f.name.value) return false;
    if (sex.value != f.sex.value) return false;
    if (parts.value != f.parts.value) return false;
    if (accnum.value != f.accnum.value) return false;
    if (studyid.value != f.studyid.value) return false;
    if (desc.value != f.desc.value) return false;
    if (comment.value != f.comment.value) return false;
    if (modalities.value != f.modalities.value) return false;
    if (institution.value != f.institution.value) return false;
    if (stations.value != f.stations.value) return false;
    if (status.value != f.status.value) return false;
    if (studyDateMode.value != f.studyDateMode.value) return false;
    if (startStudyDate.value != f.startStudyDate.value) return false;
    if (endStudyDate.value != f.endStudyDate.value) return false;
    return true;
  }

  /// Update date ranges based on studyDateMode
  void update() {
    final now = DateTime.now();
    final mode = studyDateMode.value as int;

    if (mode == today) {
      final date = now;
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(date);
    } else if (mode == yesterday) {
      final date = now.subtract(const Duration(days: 1));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(date);
    } else if (mode == thisWeek) {
      DateTime date = now;
      // Get Monday of current week (0 = Sunday, 1 = Monday, etc.)
      final weekday = date.weekday; // 1 = Monday, 7 = Sunday
      date = date.subtract(Duration(days: weekday - 1));
      startStudyDate.value = yyyymmdd(date);
      date = date.add(const Duration(days: 6));
      endStudyDate.value = yyyymmdd(date);
    } else if (mode == lastWeek) {
      DateTime date = now;
      final weekday = date.weekday;
      // Go to Monday of last week
      date = date.subtract(Duration(days: weekday - 1 + 7));
      startStudyDate.value = yyyymmdd(date);
      date = date.add(const Duration(days: 6));
      endStudyDate.value = yyyymmdd(date);
    } else if (mode == last7Days) {
      final date = now.subtract(const Duration(days: 6));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == last14Days) {
      final date = now.subtract(const Duration(days: 13));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == last21Days) {
      final date = now.subtract(const Duration(days: 20));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == last30Days) {
      final date = now.subtract(const Duration(days: 29));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == last60Days) {
      final date = now.subtract(const Duration(days: 59));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == last90Days) {
      final date = now.subtract(const Duration(days: 89));
      startStudyDate.value = yyyymmdd(date);
      endStudyDate.value = yyyymmdd(now);
    } else if (mode == thisYear) {
      final year = now.year;
      startStudyDate.value = '${year}0101';
      endStudyDate.value = '${year}1231';
    } else if (mode == thisMonth) {
      final year = now.year;
      final month = now.month;
      startStudyDate.value = '$year${twoDigit(month)}01';
      endStudyDate.value =
          '$year${twoDigit(month)}${twoDigit(_daysInMonth(month, year))}';
    } else if (mode == lastMonth) {
      final year = now.year;
      final month = now.month;
      if (month == 1) {
        startStudyDate.value = '${year - 1}1201';
        endStudyDate.value = '${year - 1}1231';
      } else {
        final lastMonthValue = month - 1;
        startStudyDate.value = '$year${twoDigit(lastMonthValue)}01';
        endStudyDate.value =
            '$year${twoDigit(lastMonthValue)}${twoDigit(_daysInMonth(lastMonthValue, year))}';
      }
    } else if (mode == custom) {
      // Custom mode - dates are set manually, no update needed
    } else {
      startStudyDate.value = '';
      endStudyDate.value = '';
    }
  }

  /// Format number as two digits (e.g., 5 -> "05")
  static String twoDigit(int n) {
    return (n < 10 ? '0' : '') + n.toString();
  }

  /// Format DateTime as YYYYMMDD string
  static String yyyymmdd(DateTime date) {
    return '${date.year}${twoDigit(date.month)}${twoDigit(date.day)}';
  }

  /// Parse YYYYMMDD string to DateTime
  static DateTime? toDate(String yyyymmdd) {
    if (yyyymmdd.length == 8) {
      try {
        final year = int.parse(yyyymmdd.substring(0, 4));
        final month = int.parse(yyyymmdd.substring(4, 6));
        final day = int.parse(yyyymmdd.substring(6, 8));
        return DateTime(year, month, day);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get number of days in a month
  static int _daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }

  /// Check if a FilterValue is defined (has a non-empty/default value)
  bool _isFilterDefined(FilterValue filter) {
    if (filter.value == null) return false;
    if (filter.value is String) {
      return (filter.value as String).isNotEmpty;
    }
    if (filter.value is int) {
      // For numeric values, consider 0 as undefined for most filters
      // but studyDateMode=0 (today) is valid, so we'll include it
      return filter.value != 0;
    }
    return true;
  }

  /// Convert filters to JSON map, only including defined filters
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (_isFilterDefined(pid)) {
      json['pid'] = {'value': pid.value, 'type': pid.type};
    }
    if (_isFilterDefined(name)) {
      json['name'] = {'value': name.value, 'type': name.type};
    }
    if (_isFilterDefined(sex)) {
      json['sex'] = {'value': sex.value, 'type': sex.type};
    }
    if (_isFilterDefined(parts)) {
      json['parts'] = {'value': parts.value, 'type': parts.type};
    }
    if (_isFilterDefined(accnum)) {
      json['accnum'] = {'value': accnum.value, 'type': accnum.type};
    }
    if (_isFilterDefined(studyid)) {
      json['studyid'] = {'value': studyid.value, 'type': studyid.type};
    }
    if (_isFilterDefined(desc)) {
      json['desc'] = {'value': desc.value, 'type': desc.type};
    }
    if (_isFilterDefined(comment)) {
      json['comment'] = {'value': comment.value, 'type': comment.type};
    }
    if (_isFilterDefined(institution)) {
      json['institution'] = {
        'value': institution.value,
        'type': institution.type
      };
    }
    if (_isFilterDefined(modalities)) {
      json['modalities'] = {'value': modalities.value, 'type': modalities.type};
    }
    if (_isFilterDefined(stations)) {
      json['stations'] = {'value': stations.value, 'type': stations.type};
    }
    if (_isFilterDefined(status)) {
      json['status'] = {'value': status.value, 'type': status.type};
    }
    if (_isFilterDefined(startStudyDate)) {
      json['startStudyDate'] = {
        'value': startStudyDate.value,
        'type': startStudyDate.type
      };
    }
    if (_isFilterDefined(endStudyDate)) {
      json['endStudyDate'] = {
        'value': endStudyDate.value,
        'type': endStudyDate.type
      };
    }
    // Always include studyDateMode if it's not the default "any" (-1)
    // or if it's a valid mode (>= 0)
    if (studyDateMode.value is int) {
      final mode = studyDateMode.value as int;
      if (mode != any) {
        json['studyDateMode'] = {
          'value': studyDateMode.value,
          'type': studyDateMode.type
        };
      }
    } else if (_isFilterDefined(studyDateMode)) {
      json['studyDateMode'] = {
        'value': studyDateMode.value,
        'type': studyDateMode.type
      };
    }

    return json;
  }
}
