// *****************************************************************************
// File        : auto_backup_service.dart
// Project     : Sri Guru Enterprise
// Description : Automatic daily Google Drive database backup.
// *****************************************************************************
//
// Responsibilities:
// • Check whether today's automatic backup is already completed.
// • Create a complete SQLite database backup through BackupManager.
// • Upload the backup to Google Drive.
// • Store the last successful backup date locally.
// • Provide manual backup support.
// • Never crash the application because of an automatic backup failure.
//
// Important:
// • This service does NOT perform Google Sign-In automatically.
// • Google authentication/session restoration is handled during app startup.
// • The actual backup process is handled by BackupManager.
// • The backup contains the complete SQLite database.
// *****************************************************************************

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sri_guru_enterprise/backup/providers/google_drive_provider.dart';

import '../auth/google_auth_service.dart';
import '../managers/backup_manager.dart';

class AutoBackupService {
  AutoBackupService._();

  // ---------------------------------------------------------------------------
  // SharedPreferences key used to store the date of the last successful
  // automatic backup.
  // ---------------------------------------------------------------------------

  static const String _lastBackupDateKey = 'last_cloud_backup_date';

  // ---------------------------------------------------------------------------
  // Check and perform the daily automatic backup.
  //
  // This method is normally called once when the application starts.
  //
  // If:
  // • No Google account is signed in, nothing is done.
  // • Today's backup already exists, nothing is done.
  // • Backup succeeds, today's date is stored.
  // • Backup fails, the error is logged but the application continues normally.
  // ---------------------------------------------------------------------------

  static Future<void> checkAndBackup() async {
    try {
      // -----------------------------------------------------------------------
      // Automatic backup should not try to sign in the user.
      //
      // The application startup already restores the Google session.
      // Therefore, only continue if a Google account is currently available.
      // -----------------------------------------------------------------------

      if (!GoogleAuthService.isSignedIn) {
        debugPrint(
          'AutoBackupService: No Google account signed in. '
              'Automatic backup skipped.',
        );
        return;
      }

      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final String today = _today();

      final String? lastBackup =
      prefs.getString(_lastBackupDateKey);

      // -----------------------------------------------------------------------
      // A successful backup has already been completed today.
      // No second automatic backup is required.
      // -----------------------------------------------------------------------

      if (lastBackup == today) {
        debugPrint(
          'AutoBackupService: Backup already completed today.',
        );
        return;
      }

      debugPrint(
        'AutoBackupService: Starting automatic database backup.',
      );

      // -----------------------------------------------------------------------
      // Use the NEW BackupManager.
      //
      // This creates the complete SQLite database backup and uploads it
      // to Google Drive using the current backup architecture.
      // -----------------------------------------------------------------------

      final GoogleDriveBackupFile? success =
      await BackupManager.instance.backupNow();

      // -----------------------------------------------------------------------
      // Only record today's date when the backup actually succeeds.
      //
      // This is important because a failed backup should be attempted again
      // on the next application start.
      // -----------------------------------------------------------------------

      if (success != null) {
        await prefs.setString(
          _lastBackupDateKey,
          today,
        );

        debugPrint(
          'AutoBackupService: Automatic backup completed successfully.',
        );
      } else {
        debugPrint(
          'AutoBackupService: Automatic backup was not completed.',
        );
      }
    } catch (e, stackTrace) {
      // -----------------------------------------------------------------------
      // Automatic backup must NEVER prevent the application from starting.
      //
      // Any backup error is logged and ignored here.
      // -----------------------------------------------------------------------

      debugPrint(
        'AutoBackupService: Automatic backup failed: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Force an immediate backup.
  //
  // Unlike checkAndBackup(), this ignores whether today's automatic backup
  // has already been completed.
  //
  // Returns:
  // • true  -> backup completed successfully.
  // • false -> backup failed or could not be completed.
  // ---------------------------------------------------------------------------

  static Future<Object?> backupNow() async {
    try {
      // -----------------------------------------------------------------------
      // Do not automatically sign in a Google account here.
      //
      // The user should already be signed in through the Backup & Restore
      // screen or through the normal Google authentication flow.
      // -----------------------------------------------------------------------

      if (!GoogleAuthService.isSignedIn) {
        debugPrint(
          'AutoBackupService: No Google account signed in.',
        );
        return false;
      }

      // -----------------------------------------------------------------------
      // Use the new full-database backup manager.
      // -----------------------------------------------------------------------

      final GoogleDriveBackupFile? success =
      await BackupManager.instance.backupNow();

      // -----------------------------------------------------------------------
      // Record the current date only after successful backup.
      // -----------------------------------------------------------------------

      if (success != null) {
        final SharedPreferences prefs =
        await SharedPreferences.getInstance();

        await prefs.setString(
          _lastBackupDateKey,
          _today(),
        );
      }

      return success;
    } catch (e, stackTrace) {
      debugPrint(
        'AutoBackupService: Manual backup failed: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Return the date of the last successful backup.
  //
  // Format:
  // yyyy-MM-dd
  //
  // Example:
  // 2026-09-16
  // ---------------------------------------------------------------------------

  static Future<String?> lastBackupDate() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      _lastBackupDateKey,
    );
  }

  // ---------------------------------------------------------------------------
  // Reset the automatic backup status.
  //
  // The next call to checkAndBackup() will treat the database as not backed
  // up for today.
  // ---------------------------------------------------------------------------

  static Future<void> reset() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      _lastBackupDateKey,
    );
  }

  // ---------------------------------------------------------------------------
  // Check whether today's backup has already been completed successfully.
  // ---------------------------------------------------------------------------

  static Future<bool> hasBackedUpToday() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(_lastBackupDateKey) == _today();
  }

  // ---------------------------------------------------------------------------
  // Generate today's date in yyyy-MM-dd format.
  // ---------------------------------------------------------------------------

  static String _today() {
    final DateTime now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${now.year}-'
        '${twoDigits(now.month)}-'
        '${twoDigits(now.day)}';
  }
}