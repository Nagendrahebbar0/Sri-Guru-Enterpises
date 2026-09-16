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
// • Date-based modules are filtered using their existing date columns.
// • Tyre Stock is treated as current stock data and is not date-filtered.
// • Tyre Billing and Alignment Billing are filtered by their bill date.
// *****************************************************************************

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/report_data.dart';
import '../services/report_date_filter_service.dart';

class ReportRepository {
  final DatabaseHelper _databaseHelper;

  ReportRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  // ===========================================================================
  // LOAD COMPLETE REPORT
  // ===========================================================================

  Future<ReportData> getReportData({
    required ReportDateRange dateRange,
  }) async {
    final Database database = await _databaseHelper.database;

    // -------------------------------------------------------------------------
    // CUSTOMERS
    //
    // Customers are not date-filtered because the current customers table
    // does not contain a customer-created/registration date.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> customers = await database.query(
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
    // The report is filtered by the document date, not expiry date.
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

    // -------------------------------------------------------------------------
    // TYRE STOCK
    //
    // Tyre Stock represents the current stock position rather than a
    // historical bill transaction.
    //
    // Therefore it is loaded as current stock and is NOT restricted by the
    // selected report date.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> tyreStocks = await database.query(
      'tyre_stocks',
      orderBy: 'id DESC',
    );

    // -------------------------------------------------------------------------
    // TYRE BILLING
    //
    // Tyre bills are historical transactions, so they are filtered using
    // their invoice date.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> tyreBills =
    await _queryByDateRange(
      database: database,
      tableName: 'tyre_bills',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    // -------------------------------------------------------------------------
    // ALIGNMENT BILLING
    //
    // Alignment bills follow the same reporting treatment as Tyre Billing.
    // They are filtered using the Alignment Bill date.
    //
    // No GST is added here because Alignment Billing is a non-GST module.
    // -------------------------------------------------------------------------

    final List<Map<String, dynamic>> alignmentBills =
    await _queryByDateRange(
      database: database,
      tableName: 'alignment_bills',
      dateColumn: 'date',
      dateRange: dateRange,
    );

    // -------------------------------------------------------------------------
    // RETURN COMPLETE REPORT DATA
    // -------------------------------------------------------------------------

    return ReportData(
      customers: customers,
      fleetServices: fleetServices,
      emissionTests: emissionTests,
      carDocuments: carDocuments,
      accessories: accessories,
      tyreStocks: tyreStocks,
      tyreBills: tyreBills,
      alignmentBills: alignmentBills,
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
    // From:
    //   selected date at 00:00:00
    //
    // To:
    //   day after the selected end date at 00:00:00
    //
    // Using "< toExclusive" makes the selected end date fully inclusive.
    // -------------------------------------------------------------------------

    final DateTime from = dateRange.from;

    final DateTime toExclusive = dateRange.to.add(
      const Duration(days: 1),
    );

    final String fromValue = from.toIso8601String();

    final String toExclusiveValue = toExclusive.toIso8601String();

    return database.query(
      tableName,
      where: '$dateColumn >= ? AND $dateColumn < ?',
      whereArgs: <Object?>[
        fromValue,
        toExclusiveValue,
      ],
      orderBy: 'id DESC',
    );
  }

  // ===========================================================================
  // INDIVIDUAL DATA LOADERS
  //
  // These methods allow individual report sections to be loaded later without
  // changing the existing module repositories.
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // CUSTOMERS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final Database database = await _databaseHelper.database;

    return database.query(
      'customers',
      orderBy: 'id DESC',
    );
  }

  // ---------------------------------------------------------------------------
  // FLEET SERVICES
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getFleetServices(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'fleet_services',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  // ---------------------------------------------------------------------------
  // EMISSION TESTS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getEmissionTests(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'emission_tests',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  // ---------------------------------------------------------------------------
  // CAR DOCUMENTS
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCarDocuments(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'car_documents',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  // ---------------------------------------------------------------------------
  // ACCESSORIES
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAccessories(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'accessories',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  // ---------------------------------------------------------------------------
  // TYRE STOCK
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTyreStocks() async {
    final Database database = await _databaseHelper.database;

    return database.query(
      'tyre_stocks',
      orderBy: 'id DESC',
    );
  }

  // ---------------------------------------------------------------------------
  // TYRE BILLING
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getTyreBills(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'tyre_bills',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }

  // ---------------------------------------------------------------------------
  // ALIGNMENT BILLING
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAlignmentBills(
      ReportDateRange dateRange,
      ) async {
    final Database database = await _databaseHelper.database;

    return _queryByDateRange(
      database: database,
      tableName: 'alignment_bills',
      dateColumn: 'date',
      dateRange: dateRange,
    );
  }
}