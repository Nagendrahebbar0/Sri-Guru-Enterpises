// ============================================================
// FILE: tyre_stock_repository.dart
//
// PURPOSE:
// Handles all SQLite operations for Tyre Stock.
//
// RESPONSIBILITIES:
// - Add stock.
// - Update stock.
// - Delete stock.
// - Get all stock.
// - Search stock.
// - Get stock by ID.
//
// SEARCH SUPPORTS:
// - Franchise
// - Vehicle Type
// - Tyre
// - Pattern
// - Size
//
// FUTURE BILLING USE:
// Tyre Billing will use this repository to:
// - Find the selected tyre.
// - Read available stock.
// - Read Sell Price.
// - Read LLP.
// - Reduce stock after successful billing.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/tyre_stock.dart';

// ============================================================
// TYRE STOCK REPOSITORY
// ============================================================

class TyreStockRepository {
  TyreStockRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // TABLE NAME
  // ============================================================

  static const String _tableName =
      'tyre_stocks';

  // ============================================================
  // GET ALL STOCK
  // ============================================================

  Future<List<TyreStock>> getAll() async {
    final Database db =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await db.query(
      _tableName,
      orderBy: 'id DESC',
    );

    return rows
        .map(TyreStock.fromMap)
        .toList();
  }

  // ============================================================
  // SEARCH
  //
  // PURPOSE:
  // Searches all important identifying fields.
  // ============================================================

  Future<List<TyreStock>> search(
      String query,
      ) async {
    final String searchText =
    query.trim();

    if (searchText.isEmpty) {
      return getAll();
    }

    final Database db =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await db.query(
      _tableName,
      where: '''
        franchise LIKE ?
        OR vehicle_type LIKE ?
        OR tyre LIKE ?
        OR pattern LIKE ?
        OR size LIKE ?
      ''',
      whereArgs: <dynamic>[
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
      ],
      orderBy: 'id DESC',
    );

    return rows
        .map(TyreStock.fromMap)
        .toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TyreStock?> getById(
      int id,
      ) async {
    final Database db =
    await _databaseHelper.database;

    final List<Map<String, dynamic>> rows =
    await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return TyreStock.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // INSERT
  //
  // PURPOSE:
  // Adds a new stock record.
  //
  // The database UNIQUE constraint prevents duplicate stock
  // records for the same franchise, vehicle type, tyre,
  // pattern and size.
  // ============================================================

  Future<int> insert(
      TyreStock stock,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return db.insert(
      _tableName,
      stock.toMap(),
      conflictAlgorithm:
      ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> update(
      TyreStock stock,
      ) async {
    if (stock.id == null) {
      throw ArgumentError(
        'Tyre Stock ID is required for update.',
      );
    }

    final Database db =
    await _databaseHelper.database;

    return db.update(
      _tableName,
      stock.toMap(),
      where: 'id = ?',
      whereArgs: <dynamic>[
        stock.id,
      ],
      conflictAlgorithm:
      ConflictAlgorithm.abort,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> delete(
      int id,
      ) async {
    final Database db =
    await _databaseHelper.database;

    return db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: <dynamic>[id],
    );
  }
}