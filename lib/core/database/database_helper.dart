// ============================================================
// FILE: database_helper.dart
//
// PURPOSE:
// Manages the local SQLite database used by Sri Guru
// Enterprises.
//
// FUNCTIONALITY:
// - Opens the SQLite database.
// - Creates database tables.
// - Provides a shared database connection.
// - Enables foreign-key support.
// - Provides database version management.
// - Provides a method to close the database.
// - Supports an optional custom database path for testing.
// ============================================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

// ============================================================
// DATABASE HELPER
// ============================================================

class DatabaseHelper {
  // ------------------------------------------------------------
  // SINGLETON INSTANCE
  // ------------------------------------------------------------

  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  // ------------------------------------------------------------
  // DATABASE INSTANCE
  // ------------------------------------------------------------

  Database? _database;

  // ------------------------------------------------------------
  // OPTIONAL DATABASE PATH
  // ------------------------------------------------------------

  final String? databasePath;

  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR FOR SINGLETON
  // ------------------------------------------------------------

  DatabaseHelper._internal()
      : databasePath = null;

  // ------------------------------------------------------------
  // TESTABLE CONSTRUCTOR
  // ------------------------------------------------------------

  DatabaseHelper.withPath(
      this.databasePath,
      );

  // ============================================================
  // DATABASE GETTER
  // ============================================================

  Future<Database> get database async {
    // ----------------------------------------------------------
    // RETURN EXISTING DATABASE
    // ----------------------------------------------------------

    if (_database != null) {
      return _database!;
    }

    // ----------------------------------------------------------
    // INITIALIZE DATABASE
    // ----------------------------------------------------------

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // INITIALIZE DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    // ----------------------------------------------------------
    // DETERMINE DATABASE PATH
    // ----------------------------------------------------------

    final String path;

    if (databasePath != null) {
      path = databasePath!;
    } else {
      final String databaseDirectory =
      await getDatabasesPath();

      path = join(
        databaseDirectory,
        'sri_guru_enterprise.db',
      );
    }

    // ----------------------------------------------------------
    // OPEN DATABASE
    // ----------------------------------------------------------

    return openDatabase(
      path,

      // --------------------------------------------------------
      // DATABASE VERSION
      //
      // Version 4 adds the Car Documents table.
      // --------------------------------------------------------

      version: 4,

      // --------------------------------------------------------
      // DATABASE CONFIGURATION
      // --------------------------------------------------------

      onConfigure: (Database db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      // --------------------------------------------------------
      // DATABASE CREATION
      //
      // Used when the database is created for the first time.
      // --------------------------------------------------------

      onCreate: (
          Database db,
          int version,
          ) async {
        await _createTables(db);
      },

      // --------------------------------------------------------
      // DATABASE UPGRADE
      // --------------------------------------------------------

      onUpgrade: (
          Database db,
          int oldVersion,
          int newVersion,
          ) async {
        // ------------------------------------------------------
        // VERSION 1 → VERSION 2
        //
        // Adds Fleet Services.
        // ------------------------------------------------------

        if (oldVersion < 2) {
          await db.execute(
            DatabaseTables.createFleetServicesTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 2 → VERSION 3
        //
        // Adds Emission Tests.
        // ------------------------------------------------------

        if (oldVersion < 3) {
          await db.execute(
            DatabaseTables.createEmissionTestsTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 3 → VERSION 4
        //
        // Adds Car Documents.
        // ------------------------------------------------------

        if (oldVersion < 4) {
          await db.execute(
            DatabaseTables.createCarDocumentsTable,
          );
        }
      },
    );
  }

  // ============================================================
  // CREATE TABLES
  // ============================================================

  Future<void> _createTables(
      Database db,
      ) async {
    // ----------------------------------------------------------
    // CUSTOMERS
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createCustomersTable,
    );

    // ----------------------------------------------------------
    // FLEET SERVICES
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createFleetServicesTable,
    );

    // ----------------------------------------------------------
    // EMISSION TESTS
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createEmissionTestsTable,
    );

    // ----------------------------------------------------------
    // CAR DOCUMENTS
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createCarDocumentsTable,
    );
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> closeDatabase() async {
    // ----------------------------------------------------------
    // CHECK WHETHER DATABASE IS OPEN
    // ----------------------------------------------------------

    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }
}