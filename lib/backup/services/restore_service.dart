// ============================================================
// FILE: restore_service.dart
//
// PURPOSE:
// Safely restores a complete Sri Guru Enterprises SQLite
// database backup.
//
// RESPONSIBILITIES:
// - Create a temporary restore-file location.
// - Validate downloaded SQLite backup files.
// - Validate the required current application tables.
// - Create a safety copy of the current database.
// - Replace the current database.
// - Reopen and verify the restored database.
// - Attempt recovery from the safety copy if restoration fails.
//
// IMPORTANT:
// - Does NOT communicate with Google Drive.
// - GoogleDriveProvider handles Google Drive communication.
// - Does NOT modify DatabaseHelper.
// - Works with the existing DatabaseHelper database path.
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
  // These are the important tables currently used by the
  // Sri Guru Enterprises application.
  //
  // The backup must contain these tables before it can replace
  // the current database.
  // ----------------------------------------------------------

  static const List<String> _requiredTables = <String>[
    'customers',
    'fleet_services',
    'emission_tests',
    'car_documents',
    'accessories',
    'tyre_stocks',
    'gst_settings',
    'tyre_bills',
    'tyre_bill_items',
    'alignment_bills',
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

  /// Restores the supplied SQLite database backup.
  ///
  /// A safety copy of the current database is created before
  /// the live database is replaced.
  Future<RestoreResult> restoreDatabase({
    required File backupFile,
  }) async {
    File? safetyBackup;

    try {
      // --------------------------------------------------------
      // STEP 1
      // Check whether the backup file exists.
      // --------------------------------------------------------

      if (!await backupFile.exists()) {
        return const RestoreResult(
          success: false,
          message:
          'The downloaded backup file was not found.',
        );
      }

      // --------------------------------------------------------
      // STEP 2
      // Validate the backup BEFORE touching the current
      // database.
      // --------------------------------------------------------

      await _validateBackupFile(
        backupFile,
      );

      // --------------------------------------------------------
      // STEP 3
      // Get the path of the live application database.
      // --------------------------------------------------------

      final String currentDatabasePath =
      await BackupService.instance.getDatabasePath();

      final File currentDatabase =
      File(currentDatabasePath);

      // --------------------------------------------------------
      // STEP 4
      // Create a safety copy of the current database.
      //
      // If anything goes wrong later, this copy can be used
      // to recover the previous database.
      // --------------------------------------------------------

      if (await currentDatabase.exists()) {
        safetyBackup = await _createSafetyBackup(
          currentDatabase,
        );
      }

      // --------------------------------------------------------
      // STEP 5
      // Close the live SQLite connection before replacing
      // the database file.
      // --------------------------------------------------------

      await DatabaseHelper.instance.closeDatabase();

      // --------------------------------------------------------
      // STEP 6
      // Replace the current database with the validated backup.
      // --------------------------------------------------------

      await backupFile.copy(
        currentDatabasePath,
      );

      // --------------------------------------------------------
      // STEP 7
      // Reopen the restored database through DatabaseHelper.
      //
      // DatabaseHelper remains responsible for its normal
      // database initialization and migration handling.
      // --------------------------------------------------------

      final Database restoredDatabase =
      await DatabaseHelper.instance.database;

      // --------------------------------------------------------
      // STEP 8
      // Verify that the restored database contains all current
      // Sri Guru Enterprises tables.
      // --------------------------------------------------------

      await _validateRestoredDatabase(
        restoredDatabase,
      );

      // --------------------------------------------------------
      // STEP 9
      // Restore succeeded.
      //
      // The old database safety copy is no longer required.
      // --------------------------------------------------------

      if (safetyBackup != null) {
        try {
          await safetyBackup.delete();
        } catch (_) {
          // Cleanup failure does not mean restore failed.
        }
      }

      // --------------------------------------------------------
      // STEP 10
      // Return successful result.
      // --------------------------------------------------------

      return const RestoreResult(
        success: true,
        message:
        'Database restored successfully.',
      );
    } catch (error) {
      // ========================================================
      // RESTORE FAILED
      // ========================================================

      // --------------------------------------------------------
      // Try to recover the previous database.
      // --------------------------------------------------------

      try {
        await DatabaseHelper.instance.closeDatabase();

        if (safetyBackup != null &&
            await safetyBackup.exists()) {
          final String currentDatabasePath =
          await BackupService.instance.getDatabasePath();

          // Replace the failed restored database with the
          // original safety copy.
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

  /// Validates the downloaded file before it is allowed to
  /// replace the live application database.
  Future<void> _validateBackupFile(
      File backupFile,
      ) async {
    // ----------------------------------------------------------
    // STEP 1
    // Check file size.
    // ----------------------------------------------------------

    final int fileSize =
    await backupFile.length();

    if (fileSize < 100) {
      throw const RestoreException(
        'The backup file is too small to be a valid '
            'SQLite database.',
      );
    }

    // ----------------------------------------------------------
    // STEP 2
    // Validate the SQLite file header.
    //
    // SQLite database files start with:
    //
    // SQLite format 3
    // ----------------------------------------------------------

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
      throw const RestoreException(
        'The backup file has an invalid SQLite header.',
      );
    }

    for (int index = 0;
    index < expectedHeader.length;
    index++) {
      if (header[index] != expectedHeader[index]) {
        throw const RestoreException(
          'The selected backup is not a valid SQLite database.',
        );
      }
    }

    // ----------------------------------------------------------
    // STEP 3
    // Open the backup separately.
    //
    // This is read-only validation.
    //
    // The live database is NOT touched yet.
    // ----------------------------------------------------------

    final Database validationDatabase =
    await openDatabase(
      backupFile.path,
      readOnly: true,
    );

    try {
      // --------------------------------------------------------
      // Verify the required application tables.
      // --------------------------------------------------------

      await _validateRestoredDatabase(
        validationDatabase,
      );
    } finally {
      // --------------------------------------------------------
      // Always close the validation database.
      // --------------------------------------------------------

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

  /// Verifies that the database contains all required current
  /// application tables.
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

    // ----------------------------------------------------------
    // Convert database table rows into a Set for fast lookup.
    // ----------------------------------------------------------

    final Set<String> tableNames =
    rows
        .map(
          (Map<String, Object?> row) =>
      row['name']?.toString() ?? '',
    )
        .toSet();

    // ----------------------------------------------------------
    // Find required tables that are missing.
    // ----------------------------------------------------------

    final List<String> missingTables =
    _requiredTables
        .where(
          (String table) =>
      !tableNames.contains(table),
    )
        .toList();

    // ----------------------------------------------------------
    // Reject the backup if any required table is missing.
    // ----------------------------------------------------------

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

  /// Creates a copy of the current database before restore.
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
        'sri_guru_enterprise_before_restore_'
            '$timestamp.db',
      ),
    );

    // ----------------------------------------------------------
    // Copy the current database.
    // ----------------------------------------------------------

    await currentDatabase.copy(
      safetyBackup.path,
    );

    // ----------------------------------------------------------
    // Confirm that the safety copy exists.
    // ----------------------------------------------------------

    if (!await safetyBackup.exists()) {
      throw const RestoreException(
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

  /// Removes unsafe characters from a downloaded backup
  /// filename before using it as a local file path.
  String _sanitizeFileName(
      String fileName,
      ) {
    final String baseName =
    path.basename(fileName);

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
// RESTORE RESULT
// ============================================================

/// Result returned after a restore operation.
class RestoreResult {
  const RestoreResult({
    required this.success,
    required this.message,
  });

  /// Whether the restore operation succeeded.
  final bool success;

  /// Human-readable result message.
  final String message;
}

// ============================================================
// RESTORE EXCEPTION
// ============================================================

/// Exception used for invalid or incompatible restore files.
class RestoreException implements Exception {
  const RestoreException(
      this.message,
      );

  final String message;

  @override
  String toString() {
    return 'RestoreException: $message';
  }
}