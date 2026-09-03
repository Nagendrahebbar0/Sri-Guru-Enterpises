// ============================================================
// FILE: car_document_repository.dart
//
// PURPOSE:
// Provides all database operations related to Car Documents.
//
// FUNCTIONALITY:
// - Adds Car Document records.
// - Retrieves all Car Document records.
// - Retrieves a Car Document by ID.
// - Updates Car Document records.
// - Deletes Car Document records.
// - Searches Car Document records.
// - Duplicates an existing Car Document record.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/car_document.dart';

// ============================================================
// CAR DOCUMENT REPOSITORY
// ============================================================

class CarDocumentRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  CarDocumentRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // ADD CAR DOCUMENT
  //
  // Inserts a new Car Document into SQLite.
  //
  // Returns:
  // Newly generated database ID.
  // ============================================================

  Future<int> addCarDocument(
      CarDocument carDocument,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> data =
    carDocument.toMap();

    // SQLite generates the ID automatically.
    data.remove('id');

    return database.insert(
      'car_documents',
      data,
    );
  }

  // ============================================================
  // GET ALL CAR DOCUMENTS
  //
  // Newest records are returned first.
  // ============================================================

  Future<List<CarDocument>> getCarDocuments() async {
    final Database database =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await database.query(
      'car_documents',
      orderBy: 'id DESC',
    );

    return rows
        .map(
          (Map<String, dynamic> row) =>
          CarDocument.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // GET CAR DOCUMENT BY ID
  // ============================================================

  Future<CarDocument?> getCarDocumentById(
      int id,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await database.query(
      'car_documents',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return CarDocument.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // UPDATE CAR DOCUMENT
  // ============================================================

  Future<int> updateCarDocument(
      CarDocument carDocument,
      ) async {
    if (carDocument.id == null) {
      throw ArgumentError(
        'Car Document ID is required for update.',
      );
    }

    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> data =
    carDocument.toMap();

    // ID is supplied through whereArgs.
    data.remove('id');

    return database.update(
      'car_documents',
      data,
      where: 'id = ?',
      whereArgs: [carDocument.id],
    );
  }

  // ============================================================
  // DELETE CAR DOCUMENT
  // ============================================================

  Future<int> deleteCarDocument(
      int id,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return database.delete(
      'car_documents',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SEARCH CAR DOCUMENTS
  //
  // Searches by:
  // - Document Type
  // - Other State Name
  // - Customer Number
  // - Customer Name
  // - Vehicle Number
  // - BBTDU ID No
  // - Payment Method
  // ============================================================

  Future<List<CarDocument>> searchCarDocuments(
      String searchText,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final String search =
    searchText.trim();

    if (search.isEmpty) {
      return getCarDocuments();
    }

    final String pattern =
        '%$search%';

    final List<Map<String, dynamic>> rows =
    await database.query(
      'car_documents',
      where: '''
        document_type LIKE ?
        OR other_state_name LIKE ?
        OR customer_number LIKE ?
        OR customer_name LIKE ?
        OR vehicle_number LIKE ?
        OR bbtdu_id_no LIKE ?
        OR payment_method LIKE ?
      ''',
      whereArgs: [
        pattern,
        pattern,
        pattern,
        pattern,
        pattern,
        pattern,
        pattern,
      ],
      orderBy: 'id DESC',
    );

    return rows
        .map(
          (Map<String, dynamic> row) =>
          CarDocument.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // DUPLICATE CAR DOCUMENT
  //
  // Creates a NEW database record using the existing information.
  //
  // The original record remains unchanged.
  // ============================================================

  Future<int> duplicateCarDocument(
      CarDocument carDocument,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> data =
    carDocument.toMap();

    // Remove original ID so SQLite creates a new one.
    data.remove('id');

    return database.insert(
      'car_documents',
      data,
    );
  }
}