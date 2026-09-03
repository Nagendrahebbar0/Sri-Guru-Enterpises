// *****************************************************************************
// File        : report_date_filter_service_test.dart
// Project     : Sri Guru Enterprises
// Description : Tests for ReportDateFilterService.
// *****************************************************************************

import 'package:flutter_test/flutter_test.dart';

import 'package:sri_guru_enterprise/services/report_date_filter_service.dart';

void main() {
  group('ReportDateFilterService - Daily', () {
    test('returns only the selected date', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.daily,
        selectedDate: DateTime(2026, 9, 3, 15, 30),
      );

      expect(range.from, DateTime(2026, 9, 3));
      expect(range.to, DateTime(2026, 9, 3));
      expect(range.dayCount, 1);
    });
  });

  group('ReportDateFilterService - Weekly', () {
    test('returns Monday to Sunday', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.weekly,
        selectedDate: DateTime(2026, 9, 3),
      );

      expect(range.from, DateTime(2026, 8, 31));
      expect(range.to, DateTime(2026, 9, 6));
      expect(range.dayCount, 7);
    });

    test('works when selected date is Sunday', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.weekly,
        selectedDate: DateTime(2026, 9, 6),
      );

      expect(range.from, DateTime(2026, 8, 31));
      expect(range.to, DateTime(2026, 9, 6));
    });
  });

  group('ReportDateFilterService - Monthly', () {
    test('returns complete September 2026', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.monthly,
        selectedDate: DateTime(2026, 9, 15),
      );

      expect(range.from, DateTime(2026, 9, 1));
      expect(range.to, DateTime(2026, 9, 30));
    });

    test('handles February in leap year', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.monthly,
        selectedDate: DateTime(2028, 2, 15),
      );

      expect(range.from, DateTime(2028, 2, 1));
      expect(range.to, DateTime(2028, 2, 29));
    });
  });

  group('ReportDateFilterService - Quarterly', () {
    test('returns Q1', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.quarterly,
        selectedDate: DateTime(2026, 2, 10),
      );

      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2026, 3, 31));
    });

    test('returns Q2', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.quarterly,
        selectedDate: DateTime(2026, 5, 10),
      );

      expect(range.from, DateTime(2026, 4, 1));
      expect(range.to, DateTime(2026, 6, 30));
    });

    test('returns Q3', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.quarterly,
        selectedDate: DateTime(2026, 9, 3),
      );

      expect(range.from, DateTime(2026, 7, 1));
      expect(range.to, DateTime(2026, 9, 30));
      expect(
        ReportDateFilterService.getQuarterLabel(
          DateTime(2026, 9, 3),
        ),
        'Q3 2026',
      );
    });

    test('returns Q4', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.quarterly,
        selectedDate: DateTime(2026, 11, 10),
      );

      expect(range.from, DateTime(2026, 10, 1));
      expect(range.to, DateTime(2026, 12, 31));
    });
  });

  group('ReportDateFilterService - Yearly', () {
    test('returns complete year', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.yearly,
        selectedDate: DateTime(2026, 9, 3),
      );

      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2026, 12, 31));
      expect(range.dayCount, 365);
    });
  });

  group('ReportDateFilterService - Custom Date', () {
    test('returns selected custom range', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.custom,
        selectedDate: DateTime(2026, 9, 3),
        customFrom: DateTime(2026, 1, 1),
        customTo: DateTime(2026, 2, 15),
      );

      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2026, 2, 15));
    });

    test('custom range is inclusive', () {
      final range = ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.custom,
        selectedDate: DateTime(2026, 9, 3),
        customFrom: DateTime(2026, 9, 1),
        customTo: DateTime(2026, 9, 3),
      );

      expect(
        ReportDateFilterService.isDateInRange(
          DateTime(2026, 9, 1),
          range,
        ),
        isTrue,
      );

      expect(
        ReportDateFilterService.isDateInRange(
          DateTime(2026, 9, 3),
          range,
        ),
        isTrue,
      );

      expect(
        ReportDateFilterService.isDateInRange(
          DateTime(2026, 8, 31),
          range,
        ),
        isFalse,
      );

      expect(
        ReportDateFilterService.isDateInRange(
          DateTime(2026, 9, 4),
          range,
        ),
        isFalse,
      );
    });

    test('throws when From Date is after To Date', () {
      expect(
            () => ReportDateFilterService.getDateRange(
          filter: ReportDateFilter.custom,
          selectedDate: DateTime(2026, 9, 3),
          customFrom: DateTime(2026, 9, 10),
          customTo: DateTime(2026, 9, 1),
        ),
        throwsArgumentError,
      );
    });

    test('throws when custom dates are missing', () {
      expect(
            () => ReportDateFilterService.getDateRange(
          filter: ReportDateFilter.custom,
          selectedDate: DateTime(2026, 9, 3),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ReportDateFilterService - Labels', () {
    test('returns correct filter labels', () {
      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.daily,
        ),
        'Daily',
      );

      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.weekly,
        ),
        'Weekly',
      );

      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.monthly,
        ),
        'Monthly',
      );

      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.quarterly,
        ),
        'Quarterly',
      );

      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.yearly,
        ),
        'Yearly',
      );

      expect(
        ReportDateFilterService.getFilterLabel(
          ReportDateFilter.custom,
        ),
        'Custom Date',
      );
    });
  });
}