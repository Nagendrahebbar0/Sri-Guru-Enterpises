// ============================================================
// FILE: backup_service.dart
//
// PURPOSE:
// Creates safe local backups of the Sri Guru Enterprises
// SQLite database.
//
// RESPONSIBILITIES:
// - Locate the live SQLite database.
// - Create a timestamped backup copy.
// - Keep the live database untouched.
// - Provide backup file information.
// - Delete temporary backup files when required.
//
// IMPORTANT:
// - Does NOT upload to Google Drive directly.
// - Google Drive upload is handled by GoogleDriveProvider.
// - Does NOT modify DatabaseHelper.
// - Does NOT close or alter the live database.
// ============================================================

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';



// ============================================================
// BACKUP SERVICE
// ============================================================

class BackupService {
  // ----------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  // ----------------------------------------------------------

  BackupService._();

  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------

  static final BackupService instance = BackupService._();

  // ----------------------------------------------------------
  // DATABASE FILE NAME
  // ----------------------------------------------------------

  static const String databaseFileName =
      'sri_guru_enterprise.db';

  // ----------------------------------------------------------
  // BACKUP DIRECTORY NAME
  //
  // Temporary/local backup files are kept separately from the
  // live SQLite database.
  // ----------------------------------------------------------

  static const String backupDirectoryName =
      'sri_guru_backups';

  // ==========================================================
  // CREATE BACKUP
  // ==========================================================

  /// Creates a timestamped copy of the current SQLite database.
  ///
  /// The original database is never modified.
  ///
  /// Returns the newly created backup file.
  Future<File> createBackup() async {
    // --------------------------------------------------------
    // Make sure the database exists and is initialized.
    //
    // We intentionally use DatabaseHelper instead of guessing
    // the database location.
    // --------------------------------------------------------

    final Database database =
    await DatabaseHelper.instance.database;

    // --------------------------------------------------------
    // Obtain the actual database path.
    // --------------------------------------------------------

    final String databasePath =
        database.path;

    final File sourceDatabase =
    File(databasePath);

    if (!await sourceDatabase.exists()) {
      throw BackupException(
        'Sri Guru Enterprises database file was not found.',
      );
    }

    // --------------------------------------------------------
    // Create local backup directory.
    // --------------------------------------------------------

    final Directory backupDirectory =
    await _getBackupDirectory();

    await backupDirectory.create(
      recursive: true,
    );

    // --------------------------------------------------------
    // Generate a unique timestamp.
    //
    // Example:
    //
    // sri_guru_enterprise_backup_2026_09_04_11_30_45.db
    // --------------------------------------------------------

    final String timestamp =
    _formatTimestamp(DateTime.now());

    final String backupFileName =
        'sri_guru_enterprise_backup_$timestamp.db';

    final File backupFile = File(
      path.join(
        backupDirectory.path,
        backupFileName,
      ),
    );

    // --------------------------------------------------------
    // Flush the database before copying.
    //
    // This asks SQLite to write pending changes to storage.
    // --------------------------------------------------------

    await database.rawQuery(
      'PRAGMA wal_checkpoint(TRUNCATE)',
    );

    // --------------------------------------------------------
    // Copy the database.
    // --------------------------------------------------------

    await sourceDatabase.copy(
      backupFile.path,
    );

    // --------------------------------------------------------
    // Verify that the backup was actually created.
    // --------------------------------------------------------

    if (!await backupFile.exists()) {
      throw BackupException(
        'Database backup file could not be created.',
      );
    }

    final int fileSize =
    await backupFile.length();

    if (fileSize <= 0) {
      throw BackupException(
        'Database backup file is empty.',
      );
    }

    return backupFile;
  }

  // ==========================================================
  // GET BACKUP DIRECTORY
  // ==========================================================

  Future<Directory> _getBackupDirectory() async {
    final Directory applicationDirectory =
    await getApplicationDocumentsDirectory();

    return Directory(
      path.join(
        applicationDirectory.path,
        backupDirectoryName,
      ),
    );
  }

  // ==========================================================
  // LIST LOCAL BACKUPS
  // ==========================================================

  /// Returns locally created backup files.
  ///
  /// Newest files are returned first.
  Future<List<File>> listLocalBackups() async {
    final Directory backupDirectory =
    await _getBackupDirectory();

    if (!await backupDirectory.exists()) {
      return <File>[];
    }

    final List<File> backupFiles = <File>[];

    await for (
    final FileSystemEntity entity
    in backupDirectory.list()
    ) {
      if (entity is File &&
          path.basename(entity.path).startsWith(
            'sri_guru_enterprise_backup_',
          ) &&
          path.extension(entity.path) == '.db') {
        backupFiles.add(entity);
      }
    }

    // --------------------------------------------------------
    // Newest backup first.
    // --------------------------------------------------------

    backupFiles.sort(
          (File a, File b) {
        return b.path.compareTo(a.path);
      },
    );

    return backupFiles;
  }

  // ==========================================================
  // DELETE LOCAL BACKUP
  // ==========================================================

  Future<bool> deleteLocalBackup(
      File backupFile,
      ) async {
    if (!await backupFile.exists()) {
      return false;
    }

    await backupFile.delete();

    return true;
  }

  // ==========================================================
  // GET DATABASE PATH
  // ==========================================================

  /// Returns the actual live SQLite database path.
  Future<String> getDatabasePath() async {
    final Database database =
    await DatabaseHelper.instance.database;

    return database.path;
  }

  // ==========================================================
  // GET DATABASE FILE
  // ==========================================================

  Future<File> getDatabaseFile() async {
    final String databasePath =
    await getDatabasePath();

    return File(databasePath);
  }

  // ==========================================================
  // CHECK DATABASE EXISTS
  // ==========================================================

  Future<bool> databaseExists() async {
    final File databaseFile =
    await getDatabaseFile();

    return databaseFile.exists();
  }

  // ==========================================================
  // TIMESTAMP FORMAT
  // ==========================================================

  String _formatTimestamp(
      DateTime dateTime,
      ) {
    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${dateTime.year}_'
        '${twoDigits(dateTime.month)}_'
        '${twoDigits(dateTime.day)}_'
        '${twoDigits(dateTime.hour)}_'
        '${twoDigits(dateTime.minute)}_'
        '${twoDigits(dateTime.second)}';
  }
}

// ============================================================
// BACKUP EXCEPTION
// ============================================================

class BackupException implements Exception {
  final String message;

  const BackupException(
      this.message,
      );

  @override
  String toString() {
    return 'BackupException: $message';
  }
}