// ============================================================
// FILE: backup_service.dart
//
// PURPOSE:
// Creates a complete SQLite database backup for
// Sri Guru Enterprises.
//
// IMPORTANT:
// - This backs up the COMPLETE SQLite database.
// - It does NOT create a customer-only JSON backup.
// - It does NOT communicate directly with Google Drive.
// - GoogleDriveProvider handles cloud upload.
// - DatabaseHelper remains responsible for the live database.
//
// DATABASE VERSION:
// Current Sri Guru Enterprises database version = 10.
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
  // ------------------------------------------------------------
  // SINGLETON
  // ------------------------------------------------------------

  BackupService._();

  static final BackupService instance = BackupService._();

  // ------------------------------------------------------------
  // BACKUP FILE NAME
  // ------------------------------------------------------------


  // ------------------------------------------------------------
  // BACKUP DIRECTORY
  // ------------------------------------------------------------

  static const String _backupDirectoryName =
      'sri_guru_backups';

  // ============================================================
  // CREATE BACKUP
  // ============================================================
  //
  // Creates a physical copy of the current SQLite database.
  //
  // The database is closed before copying so that the backup
  // represents the complete database file safely.
  // ============================================================

  Future<File> createBackup() async {
    // ----------------------------------------------------------
    // STEP 1
    // Get the current database path.
    // ----------------------------------------------------------

    final String databasePath =
    await getDatabasePath();

    final File currentDatabase =
    File(databasePath);

    // ----------------------------------------------------------
    // STEP 2
    // Verify that the database exists.
    // ----------------------------------------------------------

    if (!await currentDatabase.exists()) {
      // Opening DatabaseHelper creates the database when required.
      await DatabaseHelper.instance.database;
    }

    // ----------------------------------------------------------
    // STEP 3
    // Close the active database connection.
    //
    // This is important because the database file should not be
    // copied while SQLite is actively writing to it.
    // ----------------------------------------------------------

    await DatabaseHelper.instance.closeDatabase();

    // ----------------------------------------------------------
    // STEP 4
    // Confirm the database file now exists.
    // ----------------------------------------------------------

    if (!await currentDatabase.exists()) {
      throw BackupException(
        'The Sri Guru Enterprises database file was not found.',
      );
    }

    // ----------------------------------------------------------
    // STEP 5
    // Create backup directory.
    // ----------------------------------------------------------

    final Directory backupDirectory =
    await _getBackupDirectory();

    await backupDirectory.create(
      recursive: true,
    );

    // ----------------------------------------------------------
    // STEP 6
    // Create a timestamped backup filename.
    // ----------------------------------------------------------

    final String timestamp =
    _formatTimestamp(
      DateTime.now(),
    );

    final File backupFile = File(
      path.join(
        backupDirectory.path,
        'sri_guru_enterprise_$timestamp.db',
      ),
    );

    // ----------------------------------------------------------
    // STEP 7
    // Copy the COMPLETE SQLite database.
    // ----------------------------------------------------------

    await currentDatabase.copy(
      backupFile.path,
    );

    // ----------------------------------------------------------
    // STEP 8
    // Verify the copied file.
    // ----------------------------------------------------------

    if (!await backupFile.exists()) {
      throw BackupException(
        'The database backup could not be created.',
      );
    }

    final int size =
    await backupFile.length();

    if (size < 100) {
      throw BackupException(
        'The created database backup appears to be invalid.',
      );
    }

    // ----------------------------------------------------------
    // STEP 9
    // Reopen the application database.
    //
    // The application can continue normally after the backup.
    // ----------------------------------------------------------

    await DatabaseHelper.instance.database;

    return backupFile;
  }

  // ============================================================
  // GET DATABASE PATH
  // ============================================================
  //
  // Returns the actual SQLite database path used by
  // Sri Guru Enterprises.
  // ============================================================

  Future<String> getDatabasePath() async {
    final String databaseDirectory = await getDatabasesPath();
    return path.join(databaseDirectory, 'sri_guru_enterprise.db');
  }

  // ============================================================
  // DELETE LOCAL BACKUP
  // ============================================================
  //
  // The local backup is temporary.
  //
  // After Google Drive successfully receives the backup,
  // BackupManager deletes this temporary copy.
  // ============================================================

  Future<void> deleteLocalBackup(
      File backupFile,
      ) async {
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
  }

  // ============================================================
  // GET BACKUP DIRECTORY
  // ============================================================

  Future<Directory> _getBackupDirectory() async {
    final Directory applicationDirectory =
    await getApplicationDocumentsDirectory();

    return Directory(
      path.join(
        applicationDirectory.path,
        _backupDirectoryName,
      ),
    );
  }

  // ============================================================
  // FORMAT TIMESTAMP
  // ============================================================

  String _formatTimestamp(
      DateTime dateTime,
      ) {
    String twoDigits(int value) {
      return value
          .toString()
          .padLeft(2, '0');
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