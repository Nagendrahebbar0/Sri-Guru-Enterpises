// ============================================================
// FILE: gst_settings_repository.dart
//
// PURPOSE:
// Provides database operations for GST Settings.
//
// FUNCTIONALITY:
// - Reads the current GST setting.
// - Saves the current GST setting.
// - Updates the existing GST setting.
//
// IMPORTANT:
// - Only ONE GST setting is maintained.
// - The setting uses id = 1.
// - SGST and CGST are calculated automatically by the model.
// - This repository does not modify Tyre Stock.
// - This repository does not modify Tyre Bills.
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/gst_setting.dart';

// ============================================================
// GST SETTINGS REPOSITORY
// ============================================================

class GstSettingsRepository {
  // ----------------------------------------------------------
  // DATABASE HELPER
  // ----------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  GstSettingsRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ==========================================================
  // CONSTANTS
  // ==========================================================

  // ----------------------------------------------------------
  // Only one GST setting is maintained.
  // ----------------------------------------------------------

  static const int settingsId = 1;

  // ----------------------------------------------------------
  // Table name.
  // ----------------------------------------------------------

  static const String tableName =
      'gst_settings';

  // ==========================================================
  // GET CURRENT GST SETTING
  // ==========================================================

  /// Returns the currently saved GST setting.
  ///
  /// Returns null when GST has not been configured yet.
  Future<GstSetting?> getCurrentSetting() async {
    // --------------------------------------------------------
    // GET DATABASE
    // --------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // --------------------------------------------------------
    // QUERY CURRENT SETTING
    // --------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[
        settingsId,
      ],
      limit: 1,
    );

    // --------------------------------------------------------
    // NO SETTING
    // --------------------------------------------------------

    if (rows.isEmpty) {
      return null;
    }

    // --------------------------------------------------------
    // CONVERT DATABASE ROW
    // --------------------------------------------------------

    return GstSetting.fromMap(
      rows.first,
    );
  }

  // ==========================================================
  // SAVE GST SETTING
  // ==========================================================

  /// Saves the current total GST rate.
  ///
  /// Since only one setting exists, this method inserts the
  /// setting when it does not exist and updates it when it does.
  Future<GstSetting> saveTotalGstRate(
      double totalGstRate,
      ) async {
    // --------------------------------------------------------
    // VALIDATE GST RATE
    // --------------------------------------------------------

    if (totalGstRate < 0 ||
        totalGstRate > 100) {
      throw ArgumentError(
        'GST rate must be between 0 and 100.',
      );
    }

    // --------------------------------------------------------
    // GET DATABASE
    // --------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // --------------------------------------------------------
    // CREATE SETTING
    // --------------------------------------------------------

    final GstSetting setting =
    GstSetting(
      id: settingsId,
      totalGstRate: totalGstRate,
      updatedAt: DateTime.now(),
    );

    // --------------------------------------------------------
    // SAVE USING REPLACE
    //
    // The primary key is always id = 1.
    //
    // Therefore:
    //
    // First save  → INSERT
    // Next save   → REPLACE existing row
    //
    // No duplicate GST settings can be created.
    // --------------------------------------------------------

    await database.insert(
      tableName,
      setting.toMap(),
      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );

    // --------------------------------------------------------
    // RETURN THE SAVED SETTING
    // --------------------------------------------------------

    return setting;
  }

  // ==========================================================
  // UPDATE GST SETTING
  // ==========================================================

  /// Updates the current GST setting.
  ///
  /// This method is kept separate for clarity at repository
  /// level, although saveTotalGstRate already handles both
  /// insert and update operations.
  Future<GstSetting> updateTotalGstRate(
      double totalGstRate,
      ) async {
    return saveTotalGstRate(
      totalGstRate,
    );
  }

// ==========================================================
// DELETE GST SETTING
//
// This is intentionally not exposed as a normal application
// operation yet.
//
// Existing tyre bills must never depend on the current GST
// setting because each bill will store its own GST rate.
// ==========================================================
}