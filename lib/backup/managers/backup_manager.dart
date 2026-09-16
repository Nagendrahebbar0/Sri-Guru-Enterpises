// ============================================================
// FILE: backup_manager.dart
//
// PURPOSE:
// Central manager for Sri Guru Enterprises backup and restore.
//
// RESPONSIBILITIES:
// - Create complete SQLite database backups.
// - Upload backups to Google Drive.
// - List Google Drive backups.
// - Restore selected Google Drive backups.
// - Restore the latest Google Drive backup.
// - Delete Google Drive backups.
// - Keep only the latest 30 Google Drive backups.
//
// IMPORTANT:
// - This manager works with complete SQLite .db files.
// - It does NOT use the old customer-only JSON backup system.
// - Google Drive communication is handled by GoogleDriveProvider.
// - Database backup creation is handled by BackupService.
// - Database restoration is handled by RestoreService.
// ============================================================

import 'dart:io';

import '../auth/google_auth_service.dart';
import '../providers/google_drive_provider.dart';
import '../services/backup_service.dart';
import '../services/restore_service.dart';

// ============================================================
// BACKUP MANAGER
// ============================================================

class BackupManager {
  BackupManager._();

  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------

  static final BackupManager instance =
  BackupManager._();

  // ----------------------------------------------------------
  // MAXIMUM GOOGLE DRIVE BACKUPS
  //
  // The newest 30 backups are retained.
  // Older backups are automatically deleted.
  // ----------------------------------------------------------

  static const int maxGoogleDriveBackups = 30;

  // ==========================================================
  // BACKUP NOW
  // ==========================================================

  /// Creates a complete SQLite database backup and uploads it
  /// to Google Drive.
  ///
  /// Returns the uploaded Google Drive backup information.
  Future<GoogleDriveBackupFile?> backupNow() async {
    File? localBackup;

    try {
      // --------------------------------------------------------
      // STEP 1
      // Make sure Google authentication is available.
      //
      // requestPermission=true allows the Drive permission to
      // be requested when it has not yet been granted.
      // --------------------------------------------------------

      final client =
      await GoogleAuthService.getDriveAuthClient(
        requestPermission: true,
      );

      if (client == null) {
        return null;
      }

      // --------------------------------------------------------
      // STEP 2
      // Create a complete SQLite database backup.
      // --------------------------------------------------------

      localBackup =
      await BackupService.instance.createBackup();

      // --------------------------------------------------------
      // STEP 3
      // Generate the filename.
      //
      // BackupService already creates a timestamped .db file,
      // so the original filename is retained.
      // --------------------------------------------------------

      final String fileName =
          localBackup.uri.pathSegments.last;

      // --------------------------------------------------------
      // STEP 4
      // Upload the database backup to Google Drive.
      // --------------------------------------------------------

      final String? uploadedFileId =
      await GoogleDriveProvider.instance
          .uploadBackupFile(
        file: localBackup,
        fileName: fileName,
      );

      if (uploadedFileId == null) {
        return null;
      }

      // --------------------------------------------------------
      // STEP 5
      // Retrieve the uploaded backup information.
      //
      // This gives the caller the actual Drive file metadata.
      // --------------------------------------------------------

      final List<GoogleDriveBackupFile> backups =
      await GoogleDriveProvider.instance
          .listBackupFiles();

      GoogleDriveBackupFile? uploadedBackup;

      for (final GoogleDriveBackupFile backup
      in backups) {
        if (backup.id == uploadedFileId) {
          uploadedBackup = backup;
          break;
        }
      }

      // --------------------------------------------------------
      // STEP 6
      // Enforce the 30-backup retention limit.
      // --------------------------------------------------------

      await _enforceRetention(
        backups,
      );

      return uploadedBackup;
    } finally {
      // --------------------------------------------------------
      // STEP 7
      // Delete the temporary local backup.
      //
      // The database backup is now stored on Google Drive.
      // --------------------------------------------------------

      if (localBackup != null) {
        try {
          await BackupService.instance
              .deleteLocalBackup(
            localBackup,
          );
        } catch (_) {
          // Temporary-file cleanup failure should not cause
          // the completed cloud backup to be reported as failed.
        }
      }
    }
  }

  // ==========================================================
  // GET AVAILABLE BACKUPS
  // ==========================================================

  /// Returns Google Drive database backups.
  ///
  /// Newest backups are returned first.
  Future<List<GoogleDriveBackupFile>>
  getAvailableBackups() async {
    // ----------------------------------------------------------
    // Make sure the user is authenticated.
    // ----------------------------------------------------------

    final client =
    await GoogleAuthService.getDriveAuthClient(
      requestPermission: true,
    );

    if (client == null) {
      return <GoogleDriveBackupFile>[];
    }

    return GoogleDriveProvider.instance
        .listBackupFiles();
  }

  // ==========================================================
  // RESTORE LATEST BACKUP
  // ==========================================================

  /// Downloads and restores the newest Google Drive backup.
  Future<RestoreResult> restoreLatestBackup() async {
    final List<GoogleDriveBackupFile> backups =
    await getAvailableBackups();

    if (backups.isEmpty) {
      return const RestoreResult(
        success: false,
        message:
        'No Google Drive backups were found.',
      );
    }

    return restoreBackup(
      backup: backups.first,
    );
  }

  // ==========================================================
  // RESTORE SELECTED BACKUP
  // ==========================================================

  /// Downloads and restores a selected Google Drive backup.
  Future<RestoreResult> restoreBackup({
    required GoogleDriveBackupFile backup,
  }) async {
    File? downloadedFile;

    try {
      // --------------------------------------------------------
      // STEP 1
      // Authenticate with Google Drive.
      // --------------------------------------------------------

      final client =
      await GoogleAuthService.getDriveAuthClient(
        requestPermission: true,
      );

      if (client == null) {
        return const RestoreResult(
          success: false,
          message:
          'Google Drive authentication was not completed.',
        );
      }

      // --------------------------------------------------------
      // STEP 2
      // Create a temporary local restore file.
      // --------------------------------------------------------

      downloadedFile =
      await RestoreService.instance
          .createTemporaryRestoreFile(
        backup.name,
      );

      // --------------------------------------------------------
      // STEP 3
      // Download the selected database.
      // --------------------------------------------------------

      final File? downloaded =
      await GoogleDriveProvider.instance
          .downloadBackupFile(
        fileId: backup.id,
        destinationFile: downloadedFile,
      );

      if (downloaded == null ||
          !await downloaded.exists()) {
        return const RestoreResult(
          success: false,
          message:
          'Unable to download the selected backup.',
        );
      }

      // --------------------------------------------------------
      // STEP 4
      // Restore the complete SQLite database.
      //
      // RestoreService performs validation and creates a
      // safety copy before replacing the live database.
      // --------------------------------------------------------

      return await RestoreService.instance
          .restoreDatabase(
        backupFile: downloaded,
      );
    } catch (error) {
      return RestoreResult(
        success: false,
        message:
        'Restore failed: $error',
      );
    } finally {
      // --------------------------------------------------------
      // STEP 5
      // Delete the temporary downloaded database.
      // --------------------------------------------------------

      if (downloadedFile != null) {
        try {
          if (await downloadedFile.exists()) {
            await downloadedFile.delete();
          }
        } catch (_) {
          // Cleanup failure does not change the restore result.
        }
      }
    }
  }

  // ==========================================================
  // DELETE BACKUP
  // ==========================================================

  /// Deletes one backup from Google Drive.
  Future<bool> deleteBackup({
    required GoogleDriveBackupFile backup,
  }) async {
    // ----------------------------------------------------------
    // Authenticate with Google Drive.
    // ----------------------------------------------------------

    final client =
    await GoogleAuthService.getDriveAuthClient(
      requestPermission: true,
    );

    if (client == null) {
      return false;
    }

    // ----------------------------------------------------------
    // Delete the selected Drive file.
    // ----------------------------------------------------------

    return GoogleDriveProvider.instance
        .deleteBackupFile(
      fileId: backup.id,
    );
  }

  // ==========================================================
  // ENFORCE BACKUP RETENTION
  // ==========================================================

  /// Keeps only the newest [maxGoogleDriveBackups] files.
  Future<void> _enforceRetention(
      List<GoogleDriveBackupFile> backups,
      ) async {
    // ----------------------------------------------------------
    // Nothing to delete when the limit has not been reached.
    // ----------------------------------------------------------

    if (backups.length <= maxGoogleDriveBackups) {
      return;
    }

    // ----------------------------------------------------------
    // The provider returns newest files first.
    //
    // Start deleting from index 30 onwards.
    // ----------------------------------------------------------

    for (int index = maxGoogleDriveBackups;
    index < backups.length;
    index++) {
      final GoogleDriveBackupFile backup =
      backups[index];

      try {
        await GoogleDriveProvider.instance
            .deleteBackupFile(
          fileId: backup.id,
        );
      } catch (_) {
        // Continue attempting to remove the remaining old
        // backups even if one deletion fails.
      }
    }
  }
}