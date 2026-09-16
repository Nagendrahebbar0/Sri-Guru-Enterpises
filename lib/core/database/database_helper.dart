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
//
// DATABASE VERSION HISTORY:
// Version 2 - Fleet Services
// Version 3 - Emission Tests
// Version 4 - Car Documents
// Version 5 - Accessories
// Version 6 - Tyre Stock
// ============================================================

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_tables.dart';

// ============================================================
// DATABASE HELPER
// ============================================================

class DatabaseHelper {
  static final DatabaseHelper instance =
  DatabaseHelper._internal();

  Database? _database;

  final String? databasePath;

  DatabaseHelper._internal()
      : databasePath = null;

  // ============================================================
  // CUSTOM DATABASE CONSTRUCTOR
  //
  // PURPOSE:
  // Allows tests to create a database at a custom location.
  // ============================================================

  DatabaseHelper.withPath(
      this.databasePath,
      );

  // ============================================================
  // DATABASE GETTER
  //
  // PURPOSE:
  // Returns the existing database connection if one is already
  // open.
  //
  // Otherwise, initializes the database.
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // DATABASE INITIALIZATION
  // ============================================================

  Future<Database> _initDatabase() async {
    final String path;

    // ----------------------------------------------------------
    // CUSTOM DATABASE PATH
    //
    // Mainly used by automated tests.
    // ----------------------------------------------------------

    if (databasePath != null) {
      path = databasePath!;
    } else {
      // --------------------------------------------------------
      // NORMAL APPLICATION DATABASE
      // --------------------------------------------------------

      final String databaseDirectory =
      await getDatabasesPath();

      path = join(
        databaseDirectory,
        'sri_guru_enterprise.db',
      );
    }

    return openDatabase(
      path,

      // --------------------------------------------------------
      // DATABASE VERSION
      //
      // Version 8 adds Tyre Billing System.
      // --------------------------------------------------------

      version: 10,

      // --------------------------------------------------------
      // DATABASE CONFIGURATION
      // --------------------------------------------------------

      onConfigure: (
          Database db,
          ) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },

      // --------------------------------------------------------
      // CREATE NEW DATABASE
      // --------------------------------------------------------

      onCreate: (
          Database db,
          int version,
          ) async {
        await _createTables(db);
      },

      // --------------------------------------------------------
      // DATABASE MIGRATION
      //
      // Existing data is preserved.
      // Only the newly required table is added for each
      // database version.
      // --------------------------------------------------------

      onUpgrade: (
          Database db,
          int oldVersion,
          int newVersion,
          ) async {
        // ------------------------------------------------------
        // VERSION 1 -> 2
        //
        // Add Fleet Services.
        // ------------------------------------------------------

        if (oldVersion < 2) {
          await db.execute(
            DatabaseTables.createFleetServicesTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 2 -> 3
        //
        // Add Emission Tests.
        // ------------------------------------------------------

        if (oldVersion < 3) {
          await db.execute(
            DatabaseTables.createEmissionTestsTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 3 -> 4
        //
        // Add Car Documents.
        // ------------------------------------------------------

        if (oldVersion < 4) {
          await db.execute(
            DatabaseTables.createCarDocumentsTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 4 -> 5
        //
        // Add Accessories.
        // ------------------------------------------------------

        if (oldVersion < 5) {
          await db.execute(
            DatabaseTables.createAccessoriesTable,
          );
        }

        // ------------------------------------------------------
        // VERSION 5 -> 6
        //
        // Add Tyre Stock.
        // ------------------------------------------------------

        if (oldVersion < 6) {
          await db.execute(
            DatabaseTables.createTyreStocksTable,
          );
        }

        // ----------------------------------------------------------
        // VERSION 7
        //
        // Adds GST Settings for the Tyre Billing module.
        // ----------------------------------------------------------

        if (oldVersion < 7) {
          await db.execute(
            DatabaseTables.createGstSettingsTable,
          );
        }

        // ============================================================
        // VERSION 8
        //
        // Adds the Tyre Billing tables.
        // ============================================================

        if (oldVersion < 8) {
          await db.execute(
            DatabaseTables.createTyreBillsTable,
          );

          await db.execute(
            DatabaseTables.createTyreBillItemsTable,
          );
        }

        // Version 9: Add KMS/odometer reading to Tyre Bills.
        if (oldVersion < 9) {
          await db.execute('''
          ALTER TABLE tyre_bills
          ADD COLUMN kms INTEGER NOT NULL DEFAULT 0
        ''');
        }

        // ============================================================
        // VERSION 10
        // ============================================================
        //
        // Adds the Alignment Billing table.
        //
        // Existing customer, fleet, emission, accessories,
        // tyre stock, GST and tyre billing data are untouched.
        // ============================================================

        if (oldVersion < 10) {
          await _createAlignmentBillsTable(db);
        }
      },
    );
  }

  // ============================================================
  // CREATE ALL TABLES
  //
  // PURPOSE:
  // Creates every table when the application is installed
  // with a completely new database.
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

    // ----------------------------------------------------------
    // ACCESSORIES
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createAccessoriesTable,
    );

    // ----------------------------------------------------------
    // TYRE STOCK
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createTyreStocksTable,
    );

    // ----------------------------------------------------------
    // GST SETTINGS
    //
    // Used by the Tyre Billing module.
    // ----------------------------------------------------------

    await db.execute(
      DatabaseTables.createGstSettingsTable,
    );

    // ============================================================
    // TYRE BILLING
    //
    // Creates the Tyre Billing tables for a new installation.
    // ============================================================

    await db.execute(
      DatabaseTables.createTyreBillsTable,
    );

    await db.execute(
      DatabaseTables.createTyreBillItemsTable,
    );

    // Create Alignment Billing table.
    await _createAlignmentBillsTable(db);
  }


  // ============================================================
  // CREATE ALIGNMENT BILLS TABLE
  // ============================================================
  //
  // Stores all Simple Alignment Bill records.
  //
  // Alignment Billing is intentionally kept separate from
  // Tyre Billing because Alignment Bills do not use GST.
  //
  // ============================================================

  Future<void> _createAlignmentBillsTable(
      Database db,
      ) async {
    await db.execute('''
    CREATE TABLE alignment_bills (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bill_number TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      customer_id INTEGER,
      customer_name TEXT NOT NULL,
      customer_number TEXT NOT NULL,
      address TEXT,
      vehicle_number TEXT NOT NULL,
      kms INTEGER NOT NULL DEFAULT 0,
      service TEXT NOT NULL,
      quantity REAL NOT NULL DEFAULT 1,
      rate REAL NOT NULL DEFAULT 0,
      amount REAL NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL,
      remarks TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''');
  }
  // ============================================================
  // CLOSE DATABASE
  //
  // PURPOSE:
  // Closes the current SQLite connection.
  // ============================================================

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }
}