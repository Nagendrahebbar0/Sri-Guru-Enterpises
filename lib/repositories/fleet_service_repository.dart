// ============================================================
// FILE: fleet_service_repository.dart
//
// PURPOSE:
// Provides all database operations related to Fleet Services.
//
// FUNCTIONALITY:
// - Adds Fleet Service records.
// - Retrieves all Fleet Service records.
// - Retrieves a Fleet Service by ID.
// - Updates Fleet Service records.
// - Deletes Fleet Service records.
// - Searches Fleet Service records.
// - Duplicates an existing Fleet Service record.
//
// ARCHITECTURE:
//
// Fleet Screen
//       ↓
// FleetServiceRepository
//       ↓
// DatabaseHelper
//       ↓
// SQLite
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/fleet_service.dart';

// ============================================================
// FLEET SERVICE REPOSITORY
//
// This class is responsible for communicating with the
// fleet_services table in SQLite.
//
// The UI will use this class instead of directly accessing
// SQLite.
// ============================================================

class FleetServiceRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  //
  // Uses the application's single shared DatabaseHelper.
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // CONSTRUCTOR
  //
  // Allows DatabaseHelper to be supplied to the repository.
  //
  // By default, the application's Singleton instance is used.
  // ============================================================

  FleetServiceRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // ADD FLEET SERVICE
  //
  // Inserts a new Fleet Service record into the database.
  //
  // Returns:
  // The newly created database ID.
  // ============================================================

  Future<int> addFleetService(
      FleetService fleetService,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // CONVERT FLEET SERVICE TO DATABASE MAP
    // ----------------------------------------------------------

    final Map<String, dynamic> fleetData =
    fleetService.toMap();

    // ----------------------------------------------------------
    // REMOVE ID
    //
    // SQLite automatically generates the ID for a new record.
    // ----------------------------------------------------------

    fleetData.remove('id');

    // ----------------------------------------------------------
    // INSERT FLEET SERVICE
    // ----------------------------------------------------------

    return database.insert(
      'fleet_services',
      fleetData,
    );
  }

  // ============================================================
  // GET ALL FLEET SERVICES
  //
  // Retrieves every Fleet Service record.
  //
  // Newest records are returned first.
  // ============================================================

  Future<List<FleetService>> getFleetServices() async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // QUERY FLEET SERVICES
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'fleet_services',
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT DATABASE ROWS TO OBJECTS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          FleetService.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // GET FLEET SERVICE BY ID
  //
  // Retrieves one Fleet Service using its SQLite ID.
  //
  // Returns null if the record does not exist.
  // ============================================================

  Future<FleetService?> getFleetServiceById(
      int id,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // FIND FLEET SERVICE
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'fleet_services',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    // ----------------------------------------------------------
    // RECORD NOT FOUND
    // ----------------------------------------------------------

    if (rows.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // RETURN FLEET SERVICE
    // ----------------------------------------------------------

    return FleetService.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // UPDATE FLEET SERVICE
  //
  // Updates an existing Fleet Service record.
  //
  // Returns:
  // Number of rows updated.
  // ============================================================

  Future<int> updateFleetService(
      FleetService fleetService,
      ) async {
    // ----------------------------------------------------------
    // RECORD MUST HAVE AN ID
    //
    // SQLite needs the ID to know which record to update.
    // ----------------------------------------------------------

    if (fleetService.id == null) {
      throw ArgumentError(
        'Fleet Service ID is required when updating a '
            'Fleet Service.',
      );
    }

    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // CONVERT OBJECT TO DATABASE MAP
    // ----------------------------------------------------------

    final Map<String, dynamic> fleetData =
    fleetService.toMap();

    // ----------------------------------------------------------
    // DO NOT UPDATE PRIMARY KEY
    // ----------------------------------------------------------

    fleetData.remove('id');

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------

    return database.update(
      'fleet_services',
      fleetData,
      where: 'id = ?',
      whereArgs: [fleetService.id],
    );
  }

  // ============================================================
  // DELETE FLEET SERVICE
  //
  // Deletes a Fleet Service using its database ID.
  //
  // Returns:
  // Number of rows deleted.
  // ============================================================

  Future<int> deleteFleetService(
      int id,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // DELETE RECORD
    // ----------------------------------------------------------

    return database.delete(
      'fleet_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SEARCH FLEET SERVICES
  //
  // Searches by:
  //
  // - Vehicle Number
  // - Customer Number
  // - Vehicle Brand
  // - Vehicle Type
  // - Work Done
  //
  // Partial matches are supported.
  // ============================================================

  Future<List<FleetService>> searchFleetServices(
      String searchText,
      ) async {
    // ----------------------------------------------------------
    // REMOVE UNNECESSARY SPACES
    // ----------------------------------------------------------

    final String search =
    searchText.trim();

    // ----------------------------------------------------------
    // EMPTY SEARCH
    //
    // Return all records.
    // ----------------------------------------------------------

    if (search.isEmpty) {
      return getFleetServices();
    }

    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // SEARCH DATABASE
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'fleet_services',
      where: '''
        vehicle_number LIKE ?
        OR customer_number LIKE ?
        OR vehicle_brand LIKE ?
        OR vehicle_type LIKE ?
        OR work_done LIKE ?
      ''',
      whereArgs: [
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
        '%$search%',
      ],
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT RESULTS TO OBJECTS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          FleetService.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // DUPLICATE FLEET SERVICE
  //
  // Creates a NEW Fleet Service record using an existing
  // Fleet Service as the source.
  //
  // IMPORTANT:
  //
  // The original record is NOT modified.
  //
  // The original ID is removed before insertion, allowing
  // SQLite to generate a new ID.
  //
  // The UI can later modify fields such as:
  //
  // - Date
  // - Odometer
  // - Work Done
  //
  // before saving the duplicated record.
  // ============================================================

  Future<int> duplicateFleetService(
      FleetService fleetService,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // COPY EXISTING DATA
    //
    // Creating a new Map prevents us from modifying the
    // original FleetService object's data.
    // ----------------------------------------------------------

    final Map<String, dynamic> fleetData =
    Map<String, dynamic>.from(
      fleetService.toMap(),
    );

    // ----------------------------------------------------------
    // REMOVE ORIGINAL ID
    //
    // This is critical.
    //
    // Without removing the ID, SQLite would attempt to use
    // the same primary key.
    //
    // Removing it creates a completely new database record.
    // ----------------------------------------------------------

    fleetData.remove('id');

    // ----------------------------------------------------------
    // INSERT DUPLICATE
    //
    // SQLite generates a new ID automatically.
    // ----------------------------------------------------------

    return database.insert(
      'fleet_services',
      fleetData,
    );
  }
}