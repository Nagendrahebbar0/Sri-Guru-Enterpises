// ============================================================
// FILE: backup_manager.dart
//
// PURPOSE:
// Coordinates backup creation, Google Drive upload,
// backup listing, restore and backup deletion.
//
// FUNCTIONALITY:
// - Creates local database backup.
// - Uploads backup to Google Drive.
// - Keeps maximum 30 backups on Google Drive.
// - Deletes older backups only after a successful upload.
// - Restores the latest backup.
// - Restores a selected backup.
// - Deletes individual Google Drive backups.
//
// IMPORTANT:
// - Google Drive is used for cloud backup.
// - Firebase is NOT used.
// - Failed uploads do NOT trigger deletion of old backups.
// ============================================================

import 'dart:io';

import '../providers/google_drive_provider.dart';
import '../services/backup_service.dart';
import '../services/restore_service.dart';

// ============================================================
// BACKUP MANAGER
// ============================================================

class BackupManager {
  BackupManager._();

  static final BackupManager instance =
  BackupManager._();

  // ============================================================
  // SERVICES
  // ============================================================

  final BackupService _backupService =
      BackupService.instance;

  final GoogleDriveProvider _driveProvider =
      GoogleDriveProvider.instance;

  final RestoreService _restoreService =
      RestoreService.instance;

  // ============================================================
  // BACKUP RETENTION
  //
  // Maximum number of backups allowed in the dedicated
  // Sri Guru Enterprises Google Drive backup folder.
  //
  // The newest 30 backups are retained.
  // Older backups are automatically deleted.
  // ============================================================

  static const int maxGoogleDriveBackups = 30;

  // ============================================================
  // BACKUP NOW
  //
  // Creates a fresh database backup and uploads it to
  // Google Drive.
  //
  // After successful upload:
  // - Existing backups are listed.
  // - Newest 30 backups are retained.
  // - Older backups are deleted.
  //
  // If upload fails:
  // - Old backups are NOT deleted.
  // ============================================================

  Future<GoogleDriveBackupFile?> backupNow() async {
    // ----------------------------------------------------------
    // CREATE LOCAL DATABASE BACKUP
    // ----------------------------------------------------------

    final File localBackup =
    await _backupService.createBackup();

    try {
      // --------------------------------------------------------
      // GET FILE NAME
      // --------------------------------------------------------

      final String fileName =
          localBackup.path.split(
            Platform.pathSeparator,
          ).last;

      // --------------------------------------------------------
      // UPLOAD BACKUP TO GOOGLE DRIVE
      // --------------------------------------------------------

      final String? driveFileId =
      await _driveProvider.uploadBackupFile(
        file: localBackup,
        fileName: fileName,
      );

      // --------------------------------------------------------
      // UPLOAD WAS NOT COMPLETED
      //
      // Do NOT delete any existing Google Drive backups.
      // --------------------------------------------------------

      if (driveFileId == null) {
        return null;
      }

      // --------------------------------------------------------
      // GET UPDATED BACKUP LIST
      //
      // This is done only after successful upload.
      // --------------------------------------------------------

      final List<GoogleDriveBackupFile> backups =
      await _driveProvider.listBackupFiles();

      // --------------------------------------------------------
      // ENFORCE 30-BACKUP RETENTION POLICY
      // --------------------------------------------------------

      await _enforceBackupRetention(
        backups,
      );

      // --------------------------------------------------------
      // FIND THE NEWLY UPLOADED BACKUP
      // --------------------------------------------------------

      for (final GoogleDriveBackupFile backup
      in backups) {
        if (backup.id == driveFileId) {
          return backup;
        }
      }

      // --------------------------------------------------------
      // FALLBACK
      //
      // The upload was successful even if the newly uploaded
      // file was not returned by the listing operation.
      // --------------------------------------------------------

      return GoogleDriveBackupFile(
        id: driveFileId,
        name: fileName,
      );
    } finally {
      // --------------------------------------------------------
      // DELETE TEMPORARY LOCAL BACKUP
      //
      // The local backup is only temporary.
      // The permanent backup is stored on Google Drive.
      // --------------------------------------------------------

      try {
        await _backupService.deleteLocalBackup(
          localBackup,
        );
      } catch (_) {
        // ------------------------------------------------------
        // Failure to remove temporary file must not affect
        // the completed Google Drive backup.
        // ------------------------------------------------------
      }
    }
  }

  // ============================================================
  // ENFORCE BACKUP RETENTION
  //
  // Keeps the newest 30 backups.
  //
  // The GoogleDriveProvider already returns backups ordered
  // by createdTime descending:
  //
  // Newest
  //   ↓
  // Oldest
  //
  // Therefore indexes:
  //
  // 0 - 29  → KEEP
  // 30+     → DELETE
  //
  // ============================================================

  Future<void> _enforceBackupRetention(
      List<GoogleDriveBackupFile> backups,
      ) async {
    // ----------------------------------------------------------
    // Nothing to delete when 30 or fewer backups exist.
    // ----------------------------------------------------------

    if (backups.length <= maxGoogleDriveBackups) {
      return;
    }

    // ----------------------------------------------------------
    // GET BACKUPS OLDER THAN THE LATEST 30.
    // ----------------------------------------------------------

    final List<GoogleDriveBackupFile> oldBackups =
    backups
        .skip(maxGoogleDriveBackups)
        .toList();

    // ----------------------------------------------------------
    // DELETE OLD BACKUPS ONE BY ONE.
    //
    // If one deletion fails, continue attempting the remaining
    // old backups.
    // ----------------------------------------------------------

    for (final GoogleDriveBackupFile backup
    in oldBackups) {
      try {
        await _driveProvider.deleteBackupFile(
          fileId: backup.id,
        );
      } catch (_) {
        // ------------------------------------------------------
        // Do not allow failure to delete one old backup to
        // break the backup operation.
        // ------------------------------------------------------
      }
    }
  }

  // ============================================================
  // GET AVAILABLE BACKUPS
  // ============================================================

  Future<List<GoogleDriveBackupFile>>
  getAvailableBackups() async {
    return _driveProvider.listBackupFiles();
  }

  // ============================================================
  // RESTORE LATEST BACKUP
  //
  // The first backup returned by Google Drive is the newest
  // backup because the provider sorts by createdTime descending.
  // ============================================================

  Future<RestoreResult> restoreLatestBackup() async {
    final List<GoogleDriveBackupFile> backups =
    await _driveProvider.listBackupFiles();

    if (backups.isEmpty) {
      return const RestoreResult(
        success: false,
        message:
        'No backup was found on Google Drive.',
      );
    }

    return restoreBackup(
      backup: backups.first,
    );
  }

  // ============================================================
  // RESTORE SELECTED BACKUP
  // ============================================================

  Future<RestoreResult> restoreBackup({
    required GoogleDriveBackupFile backup,
  }) async {
    // ----------------------------------------------------------
    // CREATE TEMPORARY RESTORE FILE
    // ----------------------------------------------------------

    final File restoreFile =
    await _restoreService
        .createTemporaryRestoreFile(
      backup.name,
    );

    try {
      // --------------------------------------------------------
      // DOWNLOAD BACKUP
      // --------------------------------------------------------

      final File? downloadedFile =
      await _driveProvider.downloadBackupFile(
        fileId: backup.id,
        destinationFile: restoreFile,
      );

      if (downloadedFile == null) {
        return const RestoreResult(
          success: false,
          message:
          'Google Drive authorization is required.',
        );
      }

      // --------------------------------------------------------
      // RESTORE DATABASE
      // --------------------------------------------------------

      return await _restoreService.restoreDatabase(
        backupFile: downloadedFile,
      );
    } finally {
      // --------------------------------------------------------
      // DELETE TEMPORARY RESTORE FILE
      // --------------------------------------------------------

      try {
        if (await restoreFile.exists()) {
          await restoreFile.delete();
        }
      } catch (_) {
        // ------------------------------------------------------
        // Temporary file cleanup failure must not change the
        // restore result.
        // ------------------------------------------------------
      }
    }
  }

  // ============================================================
  // DELETE BACKUP
  //
  // Allows the Backup & Restore screen to manually delete an
  // individual Google Drive backup.
  // ============================================================

  Future<bool> deleteBackup({
    required GoogleDriveBackupFile backup,
  }) async {
    return _driveProvider.deleteBackupFile(
      fileId: backup.id,
    );
  }
}