// ============================================================
// FILE: accessory_repository.dart
//
// PURPOSE:
// Handles all SQLite database operations for Accessories.
//
// ARCHITECTURE:
//
// Accessories Screen
//        ↓
// AccessoryRepository
//        ↓
// DatabaseHelper
//        ↓
// SQLite
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/accessory.dart';

// ============================================================
// ACCESSORY REPOSITORY
// ============================================================

class AccessoryRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  AccessoryRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // ADD ACCESSORY
  //
  // Inserts a new Accessories record.
  //
  // Returns:
  // Newly generated SQLite ID.
  // ============================================================

  Future<int> addAccessory(
      Accessory accessory,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> accessoryData =
    accessory.toMap();

    // SQLite generates the ID automatically.
    accessoryData.remove('id');

    return database.insert(
      'accessories',
      accessoryData,
    );
  }

  // ============================================================
  // GET ALL ACCESSORIES
  //
  // Newest records are returned first.
  // ============================================================

  Future<List<Accessory>> getAccessories() async {
    final Database database =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await database.query(
      'accessories',
      orderBy: 'id DESC',
    );

    return rows
        .map(
          (Map<String, dynamic> row) =>
          Accessory.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // GET ACCESSORY BY ID
  //
  // Returns null if the record does not exist.
  // ============================================================

  Future<Accessory?> getAccessoryById(
      int id,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await database.query(
      'accessories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Accessory.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // UPDATE ACCESSORY
  //
  // Returns:
  // Number of rows updated.
  // ============================================================

  Future<int> updateAccessory(
      Accessory accessory,
      ) async {
    if (accessory.id == null) {
      throw ArgumentError(
        'Accessory ID is required when updating an '
            'Accessory record.',
      );
    }

    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> accessoryData =
    accessory.toMap();

    // Primary key must not be updated.
    accessoryData.remove('id');

    return database.update(
      'accessories',
      accessoryData,
      where: 'id = ?',
      whereArgs: [accessory.id],
    );
  }

  // ============================================================
  // DELETE ACCESSORY
  //
  // Returns:
  // Number of rows deleted.
  // ============================================================

  Future<int> deleteAccessory(
      int id,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return database.delete(
      'accessories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SEARCH ACCESSORIES
  //
  // Searches by:
  //
  // - Customer Name
  // - Customer Number
  // - Item
  // - Payment Method
  // - Remarks
  // ============================================================

  Future<List<Accessory>> searchAccessories(
      String searchText,
      ) async {
    final String search =
    searchText.trim();

    // Empty search returns all records.
    if (search.isEmpty) {
      return getAccessories();
    }

    final Database database =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await database.query(
      'accessories',
      where: '''
        customer_name LIKE ?
        OR customer_number LIKE ?
        OR item LIKE ?
        OR payment_method LIKE ?
        OR remarks LIKE ?
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

    return rows
        .map(
          (Map<String, dynamic> row) =>
          Accessory.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // DUPLICATE ACCESSORY
  //
  // Creates a completely new database record.
  //
  // The original record remains unchanged.
  // ============================================================

  Future<int> duplicateAccessory(
      Accessory accessory,
      ) async {
    final Database database =
    await _databaseHelper.database;

    final Map<String, dynamic> accessoryData =
    Map<String, dynamic>.from(
      accessory.toMap(),
    );

    // Remove the original ID.
    // SQLite will create a new ID.
    accessoryData.remove('id');

    return database.insert(
      'accessories',
      accessoryData,
    );
  }
}