// *****************************************************************************
// File        : report_repository.dart
// Project     : Sri Guru Enterprises
// Description : Reads enterprise data from SQLite for the Report module.
//
// IMPORTANT:
// • This repository is READ-ONLY.
// • Existing module repositories are not modified.
// • Customers are not date-filtered because the current customer table has
//   no customer-created date.
// • Fleet Services, Emission Tests, Car Documents and Accessories are filtered
//   using their existing date columns.
// *****************************************************************************

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/report_data.dart';
import '../services/report_date_filter_service.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ===========================================================================
  // LOAD COMPLETE REPORT
  // ===========================================================================

  Future<ReportData> getReportData({
    required ReportDateRange dateRange,
  }) async {
    final Database database =
    await _databaseHelper.database;

    // -------------------------------------------------------------------------
    // CUSTOMERS
    //
    // Customers are not date-filtered because the current customers table
    // does not contain a created/registration date.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> customers =
    await database.query(
      'customers',
      orderBy: 'id DESC',
    );

    // -------------------------------------------------------------------------
    // FLEET SERVICES
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> fleetServices =
    await _queryByDateRange(
      database: database,
      tableName: 'fleet_services',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    // -------------------------------------------------------------------------
    // EMISSION TESTS
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> emissionTests =
    await _queryByDateRange(
      database: database,
      tableName: 'emission_tests',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    // -------------------------------------------------------------------------
    // CAR DOCUMENTS
    //
    // The report is filtered by the document DATE, not EXPIRY DATE.
    //
    // Expiry reminders are a separate feature and should not change what
    // belongs to a historical report period.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> carDocuments =
    await _queryByDateRange(
      database: database,
      tableName: 'car_documents',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    // -------------------------------------------------------------------------
    // ACCESSORIES
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> accessories =
    await _queryByDateRange(
      database: database,
      tableName: 'accessories',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    return ReportData(
      customers: customers,
      fleetServices: fleetServices,
      emissionTests: emissionTests,
      carDocuments: carDocuments,
      accessories: accessories,
    );
  }

  // ===========================================================================
  // DATE-RANGE DATABASE QUERY
  // ===========================================================================

  Future<List<Map<String, dynamic>>> _queryByDateRange({
    required Database database,
    required String tableName,
    required String dateColumn,
    required ReportDateRange dateRange,
  }) async {
    // -------------------------------------------------------------------------
    // SQLite stores the application dates as ISO-style strings.
    //
    // We use:
    //
    // >= From Date 00:00:00
    // <
    // To Date + 1 day 00:00:00
    //
    // This makes the To Date completely inclusive, including records that
    // contain a time later in that day.
    // -------------------------------------------------------------------------

    final DateTime from = dateRange.from;

    final DateTime toExclusive = dateRange.to.add(
      const Duration(days: 1),
    );

    final String fromValue =
    from.toIso8601String();

    final String toExclusiveValue =
    toExclusive.toIso8601String();

    return database.query(
      tableName,
      where: '$dateColumn >= ? AND $dateColumn < ?',
      whereArgs: [
        fromValue,
        toExclusiveValue,
      ],
      orderBy: 'id DESC',
    );
  }

  // ===========================================================================
  // INDIVIDUAL DATA LOADERS
  //
  // These methods are useful later if the Report screen needs to refresh
  // individual sections without loading the complete report.
  // ===========================================================================

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final Database database =
    await _databaseHelper.database;

    return database.query(
      'customers',
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getFleetServices(
      ReportDateRange dateRange,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'fleet_services',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  Future<List<Map<String, dynamic>>> getEmissionTests(
      ReportDateRange dateRange,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'emission_tests',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  Future<List<Map<String, dynamic>>> getCarDocuments(
      ReportDateRange dateRange,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'car_documents',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  Future<List<Map<String, dynamic>>> getAccessories(
      ReportDateRange dateRange,
      ) async {
    final Database database =
    await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'accessories',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }
}