// ============================================================
// FILE: emission_test_repository.dart
//
// PURPOSE:
// Provides all database operations related to Emission Tests.
//
// FUNCTIONALITY:
// - Adds emission test records.
// - Retrieves all emission test records.
// - Retrieves an emission test by ID.
// - Updates emission test records.
// - Deletes emission test records.
// - Searches emission test records.
//
// ARCHITECTURE:
//
// Emission Screen
//       ↓
// EmissionTestRepository
//       ↓
// DatabaseHelper
//       ↓
// SQLite
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/emission_test.dart';

// ============================================================
// EMISSION TEST REPOSITORY
// ============================================================

class EmissionTestRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  EmissionTestRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // ADD EMISSION TEST
  //
  // Returns the newly created database ID.
  // ============================================================

  Future<int> addEmissionTest(
      EmissionTest emissionTest,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // PREPARE DATA
    //
    // SQLite automatically generates the ID.
    // ----------------------------------------------------------

    final Map<String, dynamic> emissionData =
    emissionTest.toMap();

    emissionData.remove('id');

    // ----------------------------------------------------------
    // INSERT RECORD
    // ----------------------------------------------------------

    return database.insert(
      'emission_tests',
      emissionData,
    );
  }

  // ============================================================
  // GET ALL EMISSION TESTS
  //
  // Returns newest records first.
  // ============================================================

  Future<List<EmissionTest>> getEmissionTests() async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // QUERY DATABASE
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'emission_tests',
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT DATABASE ROWS TO MODELS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          EmissionTest.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // GET EMISSION TEST BY ID
  // ============================================================

  Future<EmissionTest?> getEmissionTestById(
      int id,
      ) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // FIND RECORD
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'emission_tests',
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
    // RETURN RECORD
    // ----------------------------------------------------------

    return EmissionTest.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // UPDATE EMISSION TEST
  // ============================================================

  Future<int> updateEmissionTest(
      EmissionTest emissionTest,
      ) async {
    // ----------------------------------------------------------
    // ID REQUIRED
    // ----------------------------------------------------------

    if (emissionTest.id == null) {
      throw ArgumentError(
        'Emission Test ID is required when updating.',
      );
    }

    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // PREPARE DATA
    // ----------------------------------------------------------

    final Map<String, dynamic> emissionData =
    emissionTest.toMap();

    emissionData.remove('id');

    // ----------------------------------------------------------
    // UPDATE RECORD
    // ----------------------------------------------------------

    return database.update(
      'emission_tests',
      emissionData,
      where: 'id = ?',
      whereArgs: [emissionTest.id],
    );
  }

  // ============================================================
  // DELETE EMISSION TEST
  // ============================================================

  Future<int> deleteEmissionTest(
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
      'emission_tests',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SEARCH EMISSION TESTS
  //
  // Searches by:
  //
  // - Name
  // - Vehicle Number
  // - BBTDU ID Number
  //
  // BBTDU ID can be null because it is optional.
  // ============================================================

  Future<List<EmissionTest>> searchEmissionTests(
      String searchText,
      ) async {
    // ----------------------------------------------------------
    // CLEAN SEARCH TEXT
    // ----------------------------------------------------------

    final String search =
    searchText.trim();

    // ----------------------------------------------------------
    // EMPTY SEARCH
    //
    // Return all records.
    // ----------------------------------------------------------

    if (search.isEmpty) {
      return getEmissionTests();
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
      'emission_tests',
      where: '''
        name LIKE ?
        OR vehicle_number LIKE ?
        OR bbtdu_id_no LIKE ?
      ''',
      whereArgs: [
        '%$search%',
        '%$search%',
        '%$search%',
      ],
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT RESULTS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          EmissionTest.fromMap(row),
    )
        .toList();
  }
}