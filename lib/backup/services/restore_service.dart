// ============================================================
// FILE: restore_service.dart
//
// PURPOSE:
// Safely restores a Sri Guru Enterprises SQLite database.
//
// RESPONSIBILITIES:
// - Create a temporary restore-file location.
// - Validate downloaded SQLite backup files.
// - Validate required application tables.
// - Create a safety copy of the current database.
// - Replace the current database.
// - Reopen and verify the restored database.
// - Attempt recovery from the safety copy if restoration fails.
//
// IMPORTANT:
// - Does NOT communicate with Google Drive.
// - GoogleDriveProvider handles cloud communication.
// - Does NOT modify DatabaseHelper.
// - Current application database version is handled by
//   DatabaseHelper when the restored database is reopened.
// ============================================================

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


import '../../core/database/database_helper.dart';
import 'backup_service.dart';

// ============================================================
// RESTORE SERVICE
// ============================================================

class RestoreService {
  RestoreService._();

  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------

  static final RestoreService instance = RestoreService._();

  // ----------------------------------------------------------
  // TEMPORARY RESTORE DIRECTORY
  // ----------------------------------------------------------

  static const String _restoreDirectoryName =
      'sri_guru_restore';

  // ----------------------------------------------------------
  // SAFETY BACKUP DIRECTORY
  // ----------------------------------------------------------

  static const String _safetyBackupDirectoryName =
      'sri_guru_safety_backups';

  // ----------------------------------------------------------
  // REQUIRED DATABASE TABLES
  //
  // These tables represent the current application database.
  // ----------------------------------------------------------

  static const List<String> _requiredTables = <String>[
    'customers',
    'fleet_services',
    'emission_tests',
    'car_documents',
    'accessories',
  ];

  // ==========================================================
  // CREATE TEMPORARY RESTORE FILE
  // ==========================================================

  /// Creates a path where a downloaded Google Drive backup
  /// can temporarily be stored.
  ///
  /// The file itself is not created here.
  Future<File> createTemporaryRestoreFile(
      String fileName,
      ) async {
    final Directory directory =
    await _getRestoreDirectory();

    await directory.create(
      recursive: true,
    );

    final String safeFileName =
    _sanitizeFileName(fileName);

    return File(
      path.join(
        directory.path,
        safeFileName,
      ),
    );
  }

  // ==========================================================
  // RESTORE DATABASE
  // ==========================================================

  /// Restores the supplied SQLite backup.
  ///
  /// A safety copy of the current database is created first.
  Future<RestoreResult> restoreDatabase({
    required File backupFile,
  }) async {
    File? safetyBackup;

    try {
      // ------------------------------------------------------
      // STEP 1
      // Validate that the downloaded file exists.
      // ------------------------------------------------------

      if (!await backupFile.exists()) {
        return const RestoreResult(
          success: false,
          message:
          'The downloaded backup file was not found.',
        );
      }

      // ------------------------------------------------------
      // STEP 2
      // Validate the SQLite file before touching the current
      // database.
      // ------------------------------------------------------

      await _validateBackupFile(
        backupFile,
      );

      // ------------------------------------------------------
      // STEP 3
      // Get the current database path.
      // ------------------------------------------------------

      final String currentDatabasePath =
      await BackupService.instance.getDatabasePath();

      final File currentDatabase =
      File(currentDatabasePath);

      // ------------------------------------------------------
      // STEP 4
      // Create a safety copy of the current database.
      // ------------------------------------------------------

      if (await currentDatabase.exists()) {
        safetyBackup =
        await _createSafetyBackup(
          currentDatabase,
        );
      }

      // ------------------------------------------------------
      // STEP 5
      // Close the live database before replacing its file.
      // ------------------------------------------------------

      await DatabaseHelper.instance.closeDatabase();

      // ------------------------------------------------------
      // STEP 6
      // Replace the current database.
      // ------------------------------------------------------

      await backupFile.copy(
        currentDatabasePath,
      );

      // ------------------------------------------------------
      // STEP 7
      // Reopen the restored database through DatabaseHelper.
      // ------------------------------------------------------

      final Database restoredDatabase =
      await DatabaseHelper.instance.database;

      // ------------------------------------------------------
      // STEP 8
      // Verify that the restored database contains the
      // required Sri Guru Enterprises tables.
      // ------------------------------------------------------

      await _validateRestoredDatabase(
        restoredDatabase,
      );

      // ------------------------------------------------------
      // STEP 9
      // Remove the safety backup because the restore succeeded.
      // ------------------------------------------------------

      if (safetyBackup != null) {
        try {
          await safetyBackup.delete();
        } catch (_) {
          // Cleanup failure does not mean the restore failed.
        }
      }

      return const RestoreResult(
        success: true,
        message:
        'Database restored successfully.',
      );
    } catch (error) {
      // ------------------------------------------------------
      // Attempt to recover the previous database.
      // ------------------------------------------------------

      try {
        await DatabaseHelper.instance.closeDatabase();

        if (safetyBackup != null &&
            await safetyBackup.exists()) {
          final String currentDatabasePath =
          await BackupService.instance.getDatabasePath();

          await safetyBackup.copy(
            currentDatabasePath,
          );

          // Reopen the recovered database.
          await DatabaseHelper.instance.database;
        }
      } catch (_) {
        // Recovery itself failed.
        //
        // The original restore error is still returned below.
      }

      return RestoreResult(
        success: false,
        message:
        'Database restore failed: $error',
      );
    }
  }

  // ==========================================================
  // VALIDATE BACKUP FILE
  // ==========================================================

  Future<void> _validateBackupFile(
      File backupFile,
      ) async {
    // --------------------------------------------------------
    // Check file size.
    // --------------------------------------------------------

    final int fileSize =
    await backupFile.length();

    if (fileSize < 100) {
      throw RestoreException(
        'The backup file is too small to be a valid SQLite database.',
      );
    }

    // --------------------------------------------------------
    // SQLite database files begin with:
    //
    // "SQLite format 3"
    //
    // The header occupies the first 16 bytes.
    // --------------------------------------------------------

    final List<int> header =
    await _readHeader(
      backupFile,
    );

    const List<int> expectedHeader = <int>[
      0x53, // S
      0x51, // Q
      0x4c, // L
      0x69, // i
      0x74, // t
      0x65, // e
      0x20, // space
      0x66, // f
      0x6f, // o
      0x72, // r
      0x6d, // m
      0x61, // a
      0x74, // t
      0x20, // space
      0x33, // 3
      0x00, // terminating byte
    ];

    if (header.length < expectedHeader.length) {
      throw RestoreException(
        'The backup file has an invalid SQLite header.',
      );
    }

    for (int index = 0;
    index < expectedHeader.length;
    index++) {
      if (header[index] != expectedHeader[index]) {
        throw RestoreException(
          'The selected backup is not a valid SQLite database.',
        );
      }
    }

    // --------------------------------------------------------
    // Open the backup separately and inspect its tables.
    //
    // This happens BEFORE replacing the live database.
    // --------------------------------------------------------

    final Database validationDatabase =
    await openDatabase(
      backupFile.path,
      readOnly: true,
    );

    try {
      await _validateRestoredDatabase(
        validationDatabase,
      );
    } finally {
      await validationDatabase.close();
    }
  }

  // ==========================================================
  // READ SQLITE HEADER
  // ==========================================================

  Future<List<int>> _readHeader(
      File file,
      ) async {
    final RandomAccessFile randomAccessFile =
    await file.open(
      mode: FileMode.read,
    );

    try {
      return await randomAccessFile.read(
        16,
      );
    } finally {
      await randomAccessFile.close();
    }
  }

  // ==========================================================
  // VALIDATE DATABASE TABLES
  // ==========================================================

  Future<void> _validateRestoredDatabase(
      Database database,
      ) async {
    final List<Map<String, Object?>> rows =
    await database.rawQuery(
      '''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ''',
    );

    final Set<String> tableNames =
    rows
        .map(
          (Map<String, Object?> row) =>
      row['name']?.toString() ?? '',
    )
        .toSet();

    final List<String> missingTables =
    _requiredTables
        .where(
          (String table) =>
      !tableNames.contains(table),
    )
        .toList();

    if (missingTables.isNotEmpty) {
      throw RestoreException(
        'The backup is not compatible with the '
            'Sri Guru Enterprises database. '
            'Missing tables: ${missingTables.join(', ')}.',
      );
    }
  }

  // ==========================================================
  // CREATE SAFETY BACKUP
  // ==========================================================

  Future<File> _createSafetyBackup(
      File currentDatabase,
      ) async {
    final Directory directory =
    await _getSafetyBackupDirectory();

    await directory.create(
      recursive: true,
    );

    final String timestamp =
    _formatTimestamp(
      DateTime.now(),
    );

    final File safetyBackup = File(
      path.join(
        directory.path,
        'sri_guru_enterprise_before_restore_$timestamp.db',
      ),
    );

    await currentDatabase.copy(
      safetyBackup.path,
    );

    if (!await safetyBackup.exists()) {
      throw RestoreException(
        'Unable to create a safety backup before restore.',
      );
    }

    return safetyBackup;
  }

  // ==========================================================
  // RESTORE DIRECTORY
  // ==========================================================

  Future<Directory> _getRestoreDirectory() async {
    final Directory applicationDirectory =
    await getApplicationDocumentsDirectory();

    return Directory(
      path.join(
        applicationDirectory.path,
        _restoreDirectoryName,
      ),
    );
  }

  // ==========================================================
  // SAFETY BACKUP DIRECTORY
  // ==========================================================

  Future<Directory>
  _getSafetyBackupDirectory() async {
    final Directory applicationDirectory =
    await getApplicationDocumentsDirectory();

    return Directory(
      path.join(
        applicationDirectory.path,
        _safetyBackupDirectoryName,
      ),
    );
  }

  // ==========================================================
  // SANITIZE FILE NAME
  // ==========================================================

  String _sanitizeFileName(
      String fileName,
      ) {
    final String baseName =
    path.basename(fileName);

    // --------------------------------------------------------
    // Only allow a safe set of characters in the temporary
    // filename.
    // --------------------------------------------------------

    final String sanitized =
    baseName.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    if (sanitized.isEmpty) {
      return 'restore_backup.db';
    }

    return sanitized;
  }

  // ==========================================================
  // TIMESTAMP FORMAT
  // ==========================================================

  String _formatTimestamp(
      DateTime dateTime,
      ) {
    String twoDigits(int value) {
      return value.toString().padLeft(
        2,
        '0',
      );
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
// RESTORE RESULT
// ============================================================

class RestoreResult {
  final bool success;
  final String message;

  const RestoreResult({
    required this.success,
    required this.message,
  });
}

// ============================================================
// RESTORE EXCEPTION
// ============================================================

class RestoreException implements Exception {
  final String message;

  const RestoreException(
      this.message,
      );

  @override
  String toString() {
    return 'RestoreException: $message';
  }
}