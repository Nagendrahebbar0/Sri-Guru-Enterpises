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
//
// This class manages the application's SQLite database.
//
// The normal application uses:
//
// DatabaseHelper.instance
//
// Tests can create a separate DatabaseHelper using a custom
// database path.
// ============================================================

class DatabaseHelper {
  // ------------------------------------------------------------
  // SINGLETON INSTANCE
  //
  // This is the database helper used by the actual application.
  // ------------------------------------------------------------

  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  // ------------------------------------------------------------
  // DATABASE INSTANCE
  //
  // Holds the currently opened database connection.
  // ------------------------------------------------------------

  Database? _database;

  // ------------------------------------------------------------
  // OPTIONAL DATABASE PATH
  //
  // Normally this is null and the application automatically
  // creates:
  //
  // sri_guru_enterprise.db
  //
  // Tests can provide another path so they do not interfere
  // with the application's database.
  // ------------------------------------------------------------

  final String? databasePath;

  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR FOR SINGLETON
  // ------------------------------------------------------------

  DatabaseHelper._internal()
      : databasePath = null;

  // ------------------------------------------------------------
  // TESTABLE CONSTRUCTOR
  //
  // Allows tests to create a DatabaseHelper with a custom
  // database path.
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
    //
    // If a custom path was supplied, use it.
    //
    // Otherwise, use the normal application database location.
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
      // --------------------------------------------------------

      version: 3,

      // --------------------------------------------------------
      // DATABASE CONFIGURATION
      //
      // Enables SQLite foreign-key relationships.
      // --------------------------------------------------------

      onConfigure: (Database db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      // --------------------------------------------------------
      // DATABASE CREATION
      //
      // Creates all tables when the database is new.
      // --------------------------------------------------------

      onCreate: (
          Database db,
          int version,
          ) async {
        await _createTables(db);
      },

      // --------------------------------------------------------
      // DATABASE UPGRADE
      //
      // Future migrations will be added here.
      // --------------------------------------------------------

        onUpgrade: (
            Database db,
            int oldVersion,
            int newVersion,
            ) async {
          // ----------------------------------------------------------
          // VERSION 1 → VERSION 2
          //
          // Adds Fleet Services.
          // ----------------------------------------------------------

          if (oldVersion < 2) {
            await db.execute(
              DatabaseTables.createFleetServicesTable,
            );
          }

          // ----------------------------------------------------------
          // VERSION 2 → VERSION 3
          //
          // Adds Emission Tests.
          // ----------------------------------------------------------

          if (oldVersion < 3) {
            await db.execute(
              DatabaseTables.createEmissionTestsTable,
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
    // CUSTOMERS TABLE
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createCustomersTable,
    );

    // ----------------------------------------------------------
    // FLEET SERVICES TABLE
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
  }

  // ============================================================
  // CLOSE DATABASE
  // ============================================================

  Future<void> closeDatabase() async {
    // ----------------------------------------------------------
    // CHECK WHETHER DATABASE IS OPEN
    // ----------------------------------------------------------

    if (_database != null) {
      // --------------------------------------------------------
      // CLOSE DATABASE
      // --------------------------------------------------------

      await _database!.close();

      // --------------------------------------------------------
      // CLEAR REFERENCE
      // --------------------------------------------------------

      _database = null;
    }
  }
}