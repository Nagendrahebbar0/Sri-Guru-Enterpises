// ============================================================
// FILE: sms_reminder_tracker_service.dart
//
// PURPOSE:
// Tracks which Fleet Service and Car Document reminder SMS
// has already been opened for each record.
//
// STORAGE:
// SharedPreferences is used so no SQLite migration is required.
//
// REMINDER LEVELS:
// 30 days, 15 days, 7 days, 1 day, Due Today (0), Overdue (-1)
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

class SmsReminderTrackerService {
  SmsReminderTrackerService._();

  static const String _fleetPrefix = 'fleet_sms_reminder';
  static const String _carDocumentPrefix =
      'car_document_sms_reminder';

  static const List<int> trackedReminderDays = <int>[
    30,
    15,
    7,
    1,
    0,
    -1,
  ];

  static String _buildKey({
    required String prefix,
    required int recordId,
    required int reminderDay,
  }) {
    return '${prefix}_${recordId}_$reminderDay';
  }

  // ============================================================
  // FLEET SERVICE
  // ============================================================

  static Future<bool> isFleetReminderSent({
    required int recordId,
    required int reminderDay,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String key = _buildKey(
      prefix: _fleetPrefix,
      recordId: recordId,
      reminderDay: reminderDay,
    );

    return preferences.getBool(key) ?? false;
  }

  static Future<void> markFleetReminderSent({
    required int recordId,
    required int reminderDay,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String key = _buildKey(
      prefix: _fleetPrefix,
      recordId: recordId,
      reminderDay: reminderDay,
    );

    await preferences.setBool(key, true);
  }

  static Future<void> clearFleetServiceTracking({
    required int recordId,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    for (final int day in trackedReminderDays) {
      final String key = _buildKey(
        prefix: _fleetPrefix,
        recordId: recordId,
        reminderDay: day,
      );

      await preferences.remove(key);
    }
  }

  // ============================================================
  // CAR DOCUMENT
  // ============================================================

  static Future<bool> isCarDocumentReminderSent({
    required int recordId,
    required int reminderDay,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String key = _buildKey(
      prefix: _carDocumentPrefix,
      recordId: recordId,
      reminderDay: reminderDay,
    );

    return preferences.getBool(key) ?? false;
  }

  static Future<void> markCarDocumentReminderSent({
    required int recordId,
    required int reminderDay,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    final String key = _buildKey(
      prefix: _carDocumentPrefix,
      recordId: recordId,
      reminderDay: reminderDay,
    );

    await preferences.setBool(key, true);
  }

  static Future<void> clearCarDocumentTracking({
    required int recordId,
  }) async {
    final SharedPreferences preferences =
    await SharedPreferences.getInstance();

    for (final int day in trackedReminderDays) {
      final String key = _buildKey(
        prefix: _carDocumentPrefix,
        recordId: recordId,
        reminderDay: day,
      );

      await preferences.remove(key);
    }
  }
}
