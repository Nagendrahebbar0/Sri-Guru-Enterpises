// ============================================================
// FILE: fleet_service_reminder_service_test.dart
//
// PURPOSE:
// Unit tests for Fleet Service reminder calculations.
//
// TESTED:
// - Next service date calculation
// - Three calendar month calculation
// - Leap year handling
// - Days remaining
// - Due today
// - Overdue
// - 30 day reminder
// - 15 day reminder
// - 7 day reminder
// - 1 day reminder
// - Upcoming status
// - Due Soon status
// - Reminder Due status
// - Due Today status
// - Overdue status
// ============================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:sri_guru_enterprise/services/fleet_service_reminder_service.dart';

// ============================================================
// MAIN TEST ENTRY POINT
// ============================================================

void main() {
  // ============================================================
  // CALCULATE NEXT SERVICE DATE
  // ============================================================

  group(
    'calculateNextServiceDate',
        () {
      test(
        'adds exactly 3 calendar months',
            () {
          final DateTime serviceDate =
          DateTime(2026, 6, 4);

          final DateTime result =
          FleetServiceReminderService
              .calculateNextServiceDate(serviceDate);

          expect(
            result,
            DateTime(2026, 9, 4),
          );
        },
      );

      test(
        'handles January to April correctly',
            () {
          final DateTime serviceDate =
          DateTime(2026, 1, 15);

          final DateTime result =
          FleetServiceReminderService
              .calculateNextServiceDate(serviceDate);

          expect(
            result,
            DateTime(2026, 4, 15),
          );
        },
      );

      test(
        'handles year change correctly',
            () {
          final DateTime serviceDate =
          DateTime(2026, 11, 20);

          final DateTime result =
          FleetServiceReminderService
              .calculateNextServiceDate(serviceDate);

          expect(
            result,
            DateTime(2027, 2, 20),
          );
        },
      );

      test(
        'clamps invalid day to last day of target month',
            () {
          final DateTime serviceDate =
          DateTime(2026, 1, 31);

          final DateTime result =
          FleetServiceReminderService
              .calculateNextServiceDate(serviceDate);

          // April has only 30 days.
          expect(
            result,
            DateTime(2026, 4, 30),
          );
        },
      );

      test(
        'handles leap year correctly',
            () {
          final DateTime serviceDate =
          DateTime(2024, 11, 29);

          final DateTime result =
          FleetServiceReminderService
              .calculateNextServiceDate(serviceDate);

          expect(
            result,
            DateTime(2025, 2, 28),
          );
        },
      );
    },
  );

  // ============================================================
  // DAYS UNTIL SERVICE
  // ============================================================

  group(
    'daysUntilService',
        () {
      test(
        'returns positive days when service is upcoming',
            () {
          final DateTime nextServiceDate =
          DateTime(2026, 9, 4);

          final int result =
          FleetServiceReminderService.daysUntilService(
            nextServiceDate,
            today: DateTime(2026, 9, 3),
          );

          expect(result, 1);
        },
      );

      test(
        'returns zero when service is today',
            () {
          final DateTime nextServiceDate =
          DateTime(2026, 9, 3);

          final int result =
          FleetServiceReminderService.daysUntilService(
            nextServiceDate,
            today: DateTime(2026, 9, 3),
          );

          expect(result, 0);
        },
      );

      test(
        'returns negative days when service is overdue',
            () {
          final DateTime nextServiceDate =
          DateTime(2026, 9, 2);

          final int result =
          FleetServiceReminderService.daysUntilService(
            nextServiceDate,
            today: DateTime(2026, 9, 3),
          );

          expect(result, -1);
        },
      );

      test(
        'ignores time of day',
            () {
          final DateTime nextServiceDate =
          DateTime(2026, 9, 4, 23, 59);

          final int result =
          FleetServiceReminderService.daysUntilService(
            nextServiceDate,
            today: DateTime(2026, 9, 3, 1, 1),
          );

          expect(result, 1);
        },
      );
    },
  );

  // ============================================================
  // DUE TODAY
  // ============================================================

  group(
    'isDueToday',
        () {
      test(
        'returns true when service is today',
            () {
          final bool result =
          FleetServiceReminderService.isDueToday(
            DateTime(2026, 9, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns false when service is tomorrow',
            () {
          final bool result =
          FleetServiceReminderService.isDueToday(
            DateTime(2026, 9, 4),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isFalse);
        },
      );
    },
  );

  // ============================================================
  // OVERDUE
  // ============================================================

  group(
    'isOverdue',
        () {
      test(
        'returns true when service date has passed',
            () {
          final bool result =
          FleetServiceReminderService.isOverdue(
            DateTime(2026, 9, 2),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns false when service is today',
            () {
          final bool result =
          FleetServiceReminderService.isOverdue(
            DateTime(2026, 9, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isFalse);
        },
      );
    },
  );

  // ============================================================
  // REMINDER DUE
  // ============================================================

  group(
    'isReminderDue',
        () {
      test(
        'returns true 30 days before service',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 10, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns true 15 days before service',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 9, 18),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns true 7 days before service',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 9, 10),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns true 1 day before service',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 9, 4),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns true when service is due today',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 9, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );

      test(
        'returns true when service is overdue',
            () {
          final bool result =
          FleetServiceReminderService.isReminderDue(
            DateTime(2026, 9, 2),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isTrue);
        },
      );
    },
  );

  // ============================================================
  // GET REMINDER DAYS
  // ============================================================

  group(
    'getReminderDays',
        () {
      test(
        'returns 30 at 30 days',
            () {
          final int? result =
          FleetServiceReminderService.getReminderDays(
            DateTime(2026, 10, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 30);
        },
      );

      test(
        'returns 15 at 15 days',
            () {
          final int? result =
          FleetServiceReminderService.getReminderDays(
            DateTime(2026, 9, 18),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 15);
        },
      );

      test(
        'returns 7 at 7 days',
            () {
          final int? result =
          FleetServiceReminderService.getReminderDays(
            DateTime(2026, 9, 10),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 7);
        },
      );

      test(
        'returns 1 at 1 day',
            () {
          final int? result =
          FleetServiceReminderService.getReminderDays(
            DateTime(2026, 9, 4),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 1);
        },
      );

      test(
        'returns null on a non-reminder day',
            () {
          final int? result =
          FleetServiceReminderService.getReminderDays(
            DateTime(2026, 9, 20),
            today: DateTime(2026, 9, 3),
          );

          expect(result, isNull);
        },
      );
    },
  );

  // ============================================================
  // STATUS
  // ============================================================

  group(
    'getStatus',
        () {
      test(
        'returns Upcoming when more than 30 days remain',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 11, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Upcoming');
        },
      );

      test(
        'returns Due Soon when within 30 days',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 20),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Due Soon');
        },
      );

      test(
        'returns Reminder Due at 30 days',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 10, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Reminder Due');
        },
      );

      test(
        'returns Reminder Due at 15 days',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 18),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Reminder Due');
        },
      );

      test(
        'returns Reminder Due at 7 days',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 10),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Reminder Due');
        },
      );

      test(
        'returns Reminder Due at 1 day',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 4),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Reminder Due');
        },
      );

      test(
        'returns Due Today when service is today',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 3),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Due Today');
        },
      );

      test(
        'returns Overdue when service date has passed',
            () {
          final String result =
          FleetServiceReminderService.getStatus(
            DateTime(2026, 9, 2),
            today: DateTime(2026, 9, 3),
          );

          expect(result, 'Overdue');
        },
      );
    },
  );
}