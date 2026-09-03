// ============================================================
// FILE: car_document_reminder_service.dart
//
// PURPOSE:
// Provides reusable expiry-date reminder logic for Car Documents.
//
// REMINDER RULES:
// - 30 days before expiry
// - 15 days before expiry
// - 7 days before expiry
// - 1 day before expiry
// - Due Today
// - Overdue
//
// IMPORTANT:
// - No database changes are required.
// - The expiry date is supplied by the CarDocument model.
// - Date comparisons use date-only values so the time of day
//   does not affect the reminder result.
// ============================================================

class CarDocumentReminderService {
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
  // CALCULATE DAYS UNTIL EXPIRY
  // ============================================================

  static int daysUntilExpiry(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    final DateTime expiry = _dateOnly(expiryDate);
    final DateTime current = _dateOnly(today ?? DateTime.now());

    return expiry.difference(current).inDays;
  }

  // ============================================================
  // CHECK DUE TODAY
  // ============================================================

  static bool isDueToday(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    return daysUntilExpiry(
      expiryDate,
      today: today,
    ) ==
        0;
  }

  // ============================================================
  // CHECK OVERDUE
  // ============================================================

  static bool isOverdue(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    return daysUntilExpiry(
      expiryDate,
      today: today,
    ) <
        0;
  }

  // ============================================================
  // CHECK SCHEDULED REMINDER
  //
  // True only on:
  // 30, 15, 7 or 1 day before expiry.
  // ============================================================

  static bool isReminderDue(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    final int days = daysUntilExpiry(
      expiryDate,
      today: today,
    );

    return reminderDays.contains(days);
  }

  // ============================================================
  // CHECK ANY ACTIVE REMINDER
  //
  // True for:
  // - 30, 15, 7, 1 days before expiry
  // - Due Today
  // - Overdue
  // ============================================================

  static bool hasActiveReminder(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    final int days = daysUntilExpiry(
      expiryDate,
      today: today,
    );

    return days <= 0 || reminderDays.contains(days);
  }

  // ============================================================
  // GET REMINDER DAY
  //
  // Returns:
  // 30 / 15 / 7 / 1 for scheduled reminders.
  // Returns null for other dates.
  // ============================================================

  static int? getReminderDays(
      DateTime expiryDate, {
        DateTime? today,
      }) {
    final int days = daysUntilExpiry(
      expiryDate,
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
      DateTime expiryDate, {
        DateTime? today,
      }) {
    final int days = daysUntilExpiry(
      expiryDate,
      today: today,
    );

    if (days < 0) {
      return 'Expired';
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

    return 'Active';
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
