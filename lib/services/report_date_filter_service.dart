// *****************************************************************************
// File        : report_date_filter_service.dart
// Project     : Sri Guru Enterprises
// Description : Common date filtering logic for the Report module.
//
// Supported filters:
// • Daily
// • Weekly
// • Monthly
// • Quarterly
// • Yearly
// • Custom Date
//
// This service is shared by:
// • Report screen
// • Excel export
// • PDF export
//
// Important:
// The returned date range is inclusive.
// *****************************************************************************

enum ReportDateFilter {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly,
  custom,
}

/// Represents the final date range used by the Report module.
class ReportDateRange {
  final DateTime from;
  final DateTime to;

  const ReportDateRange({
    required this.from,
    required this.to,
  });

  /// Returns the number of calendar days in this range.
  int get dayCount => to.difference(from).inDays + 1;

  /// Human-readable date range.
  String get displayText {
    return '${_formatDate(from)} - ${_formatDate(to)}';
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  String toString() {
    return 'ReportDateRange(from: $from, to: $to)';
  }
}

/// Provides all date calculations required by the Report module.
class ReportDateFilterService {
  ReportDateFilterService._();

  /// Returns the date range for the selected filter.
  ///
  /// [selectedDate] is used for Daily, Weekly, Monthly, Quarterly and Yearly.
  ///
  /// [customFrom] and [customTo] are required for Custom Date.
  static ReportDateRange getDateRange({
    required ReportDateFilter filter,
    required DateTime selectedDate,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final date = _dateOnly(selectedDate);

    switch (filter) {
      case ReportDateFilter.daily:
        return ReportDateRange(
          from: date,
          to: date,
        );

      case ReportDateFilter.weekly:
        return _getWeeklyRange(date);

      case ReportDateFilter.monthly:
        return _getMonthlyRange(date);

      case ReportDateFilter.quarterly:
        return _getQuarterlyRange(date);

      case ReportDateFilter.yearly:
        return _getYearlyRange(date);

      case ReportDateFilter.custom:
        return _getCustomRange(
          customFrom: customFrom,
          customTo: customTo,
        );
    }
  }

  /// Returns Monday to Sunday for the selected date.
  static ReportDateRange _getWeeklyRange(DateTime date) {
    // Dart weekday:
    // Monday = 1
    // Sunday = 7
    final daysFromMonday = date.weekday - DateTime.monday;

    final monday = date.subtract(
      Duration(days: daysFromMonday),
    );

    final sunday = monday.add(
      const Duration(days: 6),
    );

    return ReportDateRange(
      from: _dateOnly(monday),
      to: _dateOnly(sunday),
    );
  }

  /// Returns the first and last day of the selected month.
  static ReportDateRange _getMonthlyRange(DateTime date) {
    final firstDay = DateTime(
      date.year,
      date.month,
      1,
    );

    final lastDay = DateTime(
      date.year,
      date.month + 1,
      0,
    );

    return ReportDateRange(
      from: _dateOnly(firstDay),
      to: _dateOnly(lastDay),
    );
  }

  /// Returns the complete calendar quarter.
  ///
  /// Q1 = January - March
  /// Q2 = April - June
  /// Q3 = July - September
  /// Q4 = October - December
  static ReportDateRange _getQuarterlyRange(DateTime date) {
    final quarter = ((date.month - 1) ~/ 3) + 1;

    final firstMonth = ((quarter - 1) * 3) + 1;

    final firstDay = DateTime(
      date.year,
      firstMonth,
      1,
    );

    final lastDay = DateTime(
      date.year,
      firstMonth + 3,
      0,
    );

    return ReportDateRange(
      from: _dateOnly(firstDay),
      to: _dateOnly(lastDay),
    );
  }

  /// Returns January 1 to December 31.
  static ReportDateRange _getYearlyRange(DateTime date) {
    final firstDay = DateTime(
      date.year,
      DateTime.january,
      1,
    );

    final lastDay = DateTime(
      date.year,
      DateTime.december,
      31,
    );

    return ReportDateRange(
      from: _dateOnly(firstDay),
      to: _dateOnly(lastDay),
    );
  }

  /// Returns the user-selected custom range.
  static ReportDateRange _getCustomRange({
    required DateTime? customFrom,
    required DateTime? customTo,
  }) {
    if (customFrom == null || customTo == null) {
      throw ArgumentError(
        'Custom Date requires both customFrom and customTo.',
      );
    }

    final from = _dateOnly(customFrom);
    final to = _dateOnly(customTo);

    if (from.isAfter(to)) {
      throw ArgumentError(
        'Custom Date From Date cannot be after To Date.',
      );
    }

    return ReportDateRange(
      from: from,
      to: to,
    );
  }

  /// Converts a DateTime to date-only.
  ///
  /// This prevents time-of-day from affecting database filtering.
  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  /// Checks whether a date belongs to a report range.
  static bool isDateInRange(
      DateTime date,
      ReportDateRange range,
      ) {
    final dateOnly = _dateOnly(date);

    return !dateOnly.isBefore(range.from) &&
        !dateOnly.isAfter(range.to);
  }

  /// Returns the quarter number for a date.
  static int getQuarter(DateTime date) {
    return ((date.month - 1) ~/ 3) + 1;
  }

  /// Returns a label such as:
  ///
  /// Q1 2026
  /// Q2 2026
  /// Q3 2026
  /// Q4 2026
  static String getQuarterLabel(DateTime date) {
    return 'Q${getQuarter(date)} ${date.year}';
  }

  /// Returns a label for the selected filter.
  static String getFilterLabel(
      ReportDateFilter filter,
      ) {
    switch (filter) {
      case ReportDateFilter.daily:
        return 'Daily';

      case ReportDateFilter.weekly:
        return 'Weekly';

      case ReportDateFilter.monthly:
        return 'Monthly';

      case ReportDateFilter.quarterly:
        return 'Quarterly';

      case ReportDateFilter.yearly:
        return 'Yearly';

      case ReportDateFilter.custom:
        return 'Custom Date';
    }
  }
}