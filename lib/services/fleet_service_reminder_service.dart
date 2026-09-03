// ============================================================
// FILE: fleet_service_reminder_service.dart
//
// PURPOSE:
// Handles Fleet Service reminder calculations.
//
// RULE:
// Fleet Service Date + 3 calendar months
// = Next Fleet Service Date.
//
// Reminder days:
// 30, 15, 7 and 1 days before the next service.
//
// Due Today and Overdue are also reminder states.
//
// IMPORTANT:
// All calculations use DATE ONLY. Time of day is ignored.
// ============================================================

class FleetServiceReminderService {
  FleetServiceReminderService._();

  // ============================================================
  // REMINDER DAYS
  // ============================================================

  static const List<int> reminderDays = <int>[
    30,
    15,
    7,
    1,
  ];

  // ============================================================
  // CALCULATE NEXT SERVICE DATE
  // ============================================================

  static DateTime calculateNextServiceDate(
      DateTime lastServiceDate,
      ) {
    final DateTime serviceDate = _dateOnly(lastServiceDate);

    // Add three calendar months without relying on DateTime's
    // automatic month overflow behaviour.
    final int totalMonths =
        serviceDate.year * 12 +
            (serviceDate.month - 1) +
            3;

    final int targetYear = totalMonths ~/ 12;
    final int targetMonth = (totalMonths % 12) + 1;

    // Last valid day of the target month.
    final int lastDayOfTargetMonth = DateTime(
      targetYear,
      targetMonth + 1,
      0,
    ).day;

    final int targetDay =
    serviceDate.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : serviceDate.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
    );
  }

  // ============================================================
  // DAYS UNTIL SERVICE
  //
  // +1 = tomorrow
  //  0 = today
  // -1 = yesterday
  //
  // today is optional and is mainly useful for testing.
  // If today is not supplied, the actual current date is used.
  // ============================================================

  static int daysUntilService(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    final DateTime currentDate =
    _dateOnly(today ?? DateTime.now());

    final DateTime serviceDate =
    _dateOnly(nextServiceDate);

    return serviceDate.difference(currentDate).inDays;
  }

  // ============================================================
  // DUE TODAY
  // ============================================================

  static bool isDueToday(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    return daysUntilService(
      nextServiceDate,
      today: today,
    ) ==
        0;
  }

  // ============================================================
  // OVERDUE
  // ============================================================

  static bool isOverdue(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    return daysUntilService(
      nextServiceDate,
      today: today,
    ) <
        0;
  }

  // ============================================================
  // REMINDER DUE
  //
  // Scheduled reminders:
  // 30, 15, 7 and 1 days before.
  //
  // Also true on the due date and after the due date so that
  // an overdue customer can still be contacted.
  // ============================================================

  static bool isReminderDue(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    final int days = daysUntilService(
      nextServiceDate,
      today: today,
    );

    return reminderDays.contains(days) || days <= 0;
  }

  // ============================================================
  // GET REMINDER DAY
  // ============================================================

  static int? getReminderDays(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    final int days = daysUntilService(
      nextServiceDate,
      today: today,
    );

    if (reminderDays.contains(days)) {
      return days;
    }

    return null;
  }

  // ============================================================
  // GET STATUS
  // ============================================================

  static String getStatus(
      DateTime nextServiceDate, {
        DateTime? today,
      }) {
    final int days = daysUntilService(
      nextServiceDate,
      today: today,
    );

    if (days < 0) {
      return 'Overdue';
    }

    if (days == 0) {
      return 'Due Today';
    }

    if (reminderDays.contains(days)) {
      return 'Reminder Due';
    }

    if (days <= 30) {
      return 'Due Soon';
    }

    return 'Upcoming';
  }

  // ============================================================
  // DATE ONLY
  // ============================================================

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}