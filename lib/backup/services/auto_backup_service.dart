// ============================================================
// FILE: auto_backup_service.dart
//
// PURPOSE:
// Handles automatic daily Google Drive backups.
//
// BEHAVIOUR:
// - Auto Backup is ON by default.
// - Checks once when the application starts.
// - Creates at most one automatic backup per day.
// - Records the date only after successful backup.
// - Never prevents the application from starting.
// - Manual Backup Now is handled separately by BackupManager.
// ============================================================

import 'package:shared_preferences/shared_preferences.dart';

import '../managers/backup_manager.dart';

// ============================================================
// AUTO BACKUP SERVICE
// ============================================================

class AutoBackupService {
  AutoBackupService._();

  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------

  static final AutoBackupService instance =
  AutoBackupService._();

  // ----------------------------------------------------------
  // SHARED PREFERENCES KEYS
  // ----------------------------------------------------------

  static const String _autoBackupEnabledKey =
      'auto_backup_enabled';

  static const String _lastAutoBackupDateKey =
      'last_auto_backup_date';

  // ==========================================================
  // CHECK AND PERFORM AUTO BACKUP
  // ==========================================================

  /// Checks whether today's automatic backup has already
  /// completed.
  ///
  /// If Auto Backup is enabled and today's backup has not
  /// completed, a backup is attempted.
  ///
  /// Any failure is swallowed so application startup is never
  /// interrupted.
  static Future<bool> checkAndBackup() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      // ------------------------------------------------------
      // Auto Backup is ON by default.
      // ------------------------------------------------------

      final bool enabled =
          prefs.getBool(
            _autoBackupEnabledKey,
          ) ??
              true;

      if (!enabled) {
        return false;
      }

      // ------------------------------------------------------
      // Check whether today's backup already succeeded.
      // ------------------------------------------------------

      final String today = _today();

      final String? lastBackupDate =
      prefs.getString(
        _lastAutoBackupDateKey,
      );

      if (lastBackupDate == today) {
        return false;
      }

      // ------------------------------------------------------
      // Attempt the backup.
      // ------------------------------------------------------

      final backup =
      await BackupManager.instance.backupNow();

      if (backup == null) {
        // ----------------------------------------------------
        // Do NOT record today's date.
        //
        // This allows another startup to retry the backup.
        // ----------------------------------------------------

        return false;
      }

      // ------------------------------------------------------
      // Backup succeeded.
      // ------------------------------------------------------

      await prefs.setString(
        _lastAutoBackupDateKey,
        today,
      );

      return true;
    } catch (_) {
      // ------------------------------------------------------
      // Automatic backup must NEVER crash or block the app.
      // ------------------------------------------------------

      return false;
    }
  }

  // ==========================================================
  // ENABLE / DISABLE AUTO BACKUP
  // ==========================================================

  static Future<void> setEnabled(
      bool enabled,
      ) async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _autoBackupEnabledKey,
      enabled,
    );
  }

  // ==========================================================
  // CHECK WHETHER AUTO BACKUP IS ENABLED
  // ==========================================================

  static Future<bool> isEnabled() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      _autoBackupEnabledKey,
    ) ??
        true;
  }

  // ==========================================================
  // GET LAST SUCCESSFUL AUTO BACKUP DATE
  // ==========================================================

  static Future<String?> lastBackupDate() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      _lastAutoBackupDateKey,
    );
  }

  // ==========================================================
  // FORCE NEXT AUTO BACKUP
  // ==========================================================

  /// Removes the saved backup date.
  ///
  /// The next application startup can therefore perform an
  /// automatic backup again.
  static Future<void> reset() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      _lastAutoBackupDateKey,
    );
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  static String _today() {
    final DateTime now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${now.year}-'
        '${twoDigits(now.month)}-'
        '${twoDigits(now.day)}';
  }
}