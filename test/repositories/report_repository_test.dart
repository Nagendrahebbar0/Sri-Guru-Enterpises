// *****************************************************************************
// File        : report_repository_test.dart
// Project     : Sri Guru Enterprises
// Description : Tests ReportRepository date filtering.
//
// These tests use an isolated SQLite database so they do not interfere with
// the application's normal database.
// *****************************************************************************

import 'package:flutter_test/flutter_test.dart';


import 'package:sri_guru_enterprise/core/database/database_helper.dart';
import 'package:sri_guru_enterprise/models/report_data.dart';
import 'package:sri_guru_enterprise/repositories/report_repository.dart';
import 'package:sri_guru_enterprise/services/report_date_filter_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
class TestDatabaseHelper extends DatabaseHelper {
  TestDatabaseHelper._() : super.withPath('');

  static final TestDatabaseHelper instance =
  TestDatabaseHelper._();

  Database? _testDatabase;

  Future<void> reset() async {
    await _testDatabase?.close();
    _testDatabase = null;
  }

  @override
  Future<Database> get database async {
    if (_testDatabase != null) {
      return _testDatabase!;
    }

    _testDatabase = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE fleet_services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            vehicle_brand TEXT NOT NULL,
            vehicle_type TEXT NOT NULL,
            vehicle_number TEXT NOT NULL,
            customer_number TEXT NOT NULL,
            odometer REAL NOT NULL,
            work_done TEXT NOT NULL,
            total_count REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE emission_tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            name TEXT NOT NULL,
            vehicle_number TEXT,
            income REAL NOT NULL,
            bbtdu_id_no TEXT,
            fuel_type TEXT NOT NULL,
            payment_method TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE car_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_type TEXT NOT NULL,
            other_state_name TEXT,
            date TEXT NOT NULL,
            expiry_date TEXT NOT NULL,
            customer_number TEXT NOT NULL,
            customer_name TEXT NOT NULL,
            vehicle_number TEXT NOT NULL,
            income REAL NOT NULL,
            bbtdu_id_no TEXT,
            expense REAL NOT NULL,
            profit REAL NOT NULL,
            payment_method TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE accessories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            customer_name TEXT NOT NULL,
            customer_number TEXT NOT NULL,
            item TEXT NOT NULL,
            quantity REAL NOT NULL,
            rate REAL NOT NULL,
            total_amount REAL NOT NULL,
            payment_method TEXT NOT NULL,
            remarks TEXT NOT NULL
          )
        ''');
      },
    );

    return _testDatabase!;
  }
}

void main() {
  // ---------------------------------------------------------------------------
  // INITIALIZE SQLite FFI
  //
  // Flutter tests run on Windows in this project.
  // sqflite_common_ffi provides the SQLite implementation required by tests.
  // ---------------------------------------------------------------------------

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  // ---------------------------------------------------------------------------
  // TEST DATABASE
  // ---------------------------------------------------------------------------

  final TestDatabaseHelper databaseHelper =
      TestDatabaseHelper.instance;

  late ReportRepository repository;

  setUp(() async {
    await databaseHelper.reset();

    repository = ReportRepository(
      databaseHelper: databaseHelper,
    );

    final Database database =
    await databaseHelper.database;

    await database.insert(
      'customers',
      {
        'name': 'Test Customer',
        'phone': '9876543210',
      },
    );

    await database.insert(
      'fleet_services',
      {
        'date': DateTime(2026, 9, 1).toIso8601String(),
        'vehicle_brand': 'Toyota',
        'vehicle_type': 'Etios',
        'vehicle_number': 'KA01AB1234',
        'customer_number': '9876543210',
        'odometer': 50000,
        'work_done': 'Service',
        'total_count': 1,
      },
    );

    await database.insert(
      'fleet_services',
      {
        'date': DateTime(2026, 9, 3, 18, 30)
            .toIso8601String(),
        'vehicle_brand': 'Maruti Suzuki',
        'vehicle_type': 'Swift',
        'vehicle_number': 'KA02CD5678',
        'customer_number': '9876543210',
        'odometer': 60000,
        'work_done': 'Oil Change',
        'total_count': 2,
      },
    );

    await database.insert(
      'fleet_services',
      {
        'date': DateTime(2026, 9, 4).toIso8601String(),
        'vehicle_brand': 'Toyota',
        'vehicle_type': 'Innova',
        'vehicle_number': 'KA03EF9012',
        'customer_number': '9876543210',
        'odometer': 70000,
        'work_done': 'General Service',
        'total_count': 3,
      },
    );

    await database.insert(
      'emission_tests',
      {
        'date': DateTime(2026, 9, 2).toIso8601String(),
        'name': 'Test Customer',
        'vehicle_number': 'KA01AB1234',
        'income': 150,
        'bbtdu_id_no': null,
        'fuel_type': 'Petrol',
        'payment_method': 'Cash',
      },
    );

    await database.insert(
      'car_documents',
      {
        'document_type': 'Insurance',
        'other_state_name': null,
        'date': DateTime(2026, 9, 2).toIso8601String(),
        'expiry_date': DateTime(2027, 9, 2).toIso8601String(),
        'customer_number': '9876543210',
        'customer_name': 'Test Customer',
        'vehicle_number': 'KA01AB1234',
        'income': 1000,
        'bbtdu_id_no': null,
        'expense': 500,
        'profit': 500,
        'payment_method': 'Cash',
      },
    );

    await database.insert(
      'accessories',
      {
        'date': DateTime(2026, 9, 3).toIso8601String(),
        'customer_name': 'Test Customer',
        'customer_number': '9876543210',
        'item': 'Trip Sheet',
        'quantity': 2,
        'rate': 50,
        'total_amount': 100,
        'payment_method': 'Cash',
        'remarks': '',
      },
    );
  });

  tearDown(() async {
    await databaseHelper.reset();
  });

  group('ReportRepository', () {
    test('loads all customers regardless of report date', () async {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.daily,
        selectedDate: DateTime(2026, 9, 3),
      );

      final ReportData report =
      await repository.getReportData(
        dateRange: range,
      );

      expect(report.customers.length, 1);
    });

    test('filters Fleet Services by selected date range', () async {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.custom,
        selectedDate: DateTime(2026, 9, 3),
        customFrom: DateTime(2026, 9, 1),
        customTo: DateTime(2026, 9, 3),
      );

      final ReportData report =
      await repository.getReportData(
        dateRange: range,
      );

      expect(report.fleetServices.length, 2);
    });

    test('includes the complete To Date', () async {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.daily,
        selectedDate: DateTime(2026, 9, 3),
      );

      final ReportData report =
      await repository.getReportData(
        dateRange: range,
      );

      expect(report.fleetServices.length, 1);
      expect(
        report.fleetServices.first['vehicle_number'],
        'KA02CD5678',
      );
    });

    test('does not include records after To Date', () async {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.custom,
        selectedDate: DateTime(2026, 9, 3),
        customFrom: DateTime(2026, 9, 1),
        customTo: DateTime(2026, 9, 2),
      );

      final ReportData report =
      await repository.getReportData(
        dateRange: range,
      );

      expect(report.fleetServices.length, 1);
      expect(report.emissionTests.length, 1);
      expect(report.carDocuments.length, 1);
      expect(report.accessories.length, 0);
    });

    test('filters all dated modules using the same range', () async {
      final ReportDateRange range =
      ReportDateFilterService.getDateRange(
        filter: ReportDateFilter.custom,
        selectedDate: DateTime(2026, 9, 3),
        customFrom: DateTime(2026, 9, 1),
        customTo: DateTime(2026, 9, 3),
      );

      final ReportData report =
      await repository.getReportData(
        dateRange: range,
      );

      expect(report.fleetServices.length, 2);
      expect(report.emissionTests.length, 1);
      expect(report.carDocuments.length, 1);
      expect(report.accessories.length, 1);
    });
  });
}