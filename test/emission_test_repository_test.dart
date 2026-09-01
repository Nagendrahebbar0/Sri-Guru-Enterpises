// ============================================================
// FILE: emission_test_repository_test.dart
//
// PURPOSE:
// Tests the Emission Test database and repository functionality.
//
// FUNCTIONALITY TESTED:
// - Emission Tests table creation.
// - Add Emission Test.
// - Read Emission Tests.
// - Get Emission Test by ID.
// - Search Emission Tests.
// - Update Emission Test.
// - Delete Emission Test.
// - Verify Emission Test deletion.
//
// IMPORTANT:
// BBTDU ID No. is optional.
//
// CUSTOMER CONNECTION:
// The Emission Test currently stores the customer name directly.
// Customer ID and Customer Number are intentionally NOT stored.
//
// TEST DATABASE:
// A separate temporary SQLite database is used so this test
// cannot interfere with Customer or Fleet tests.
// ============================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sri_guru_enterprise/core/database/database_helper.dart';
import 'package:sri_guru_enterprise/models/emission_test.dart';
import 'package:sri_guru_enterprise/repositories/emission_test_repository.dart';

// ============================================================
// MAIN TEST FUNCTION
// ============================================================

void main() {
  // ==========================================================
  // INITIALIZE SQLITE FOR TESTING
  // ==========================================================

  setUpAll(() {
    sqfliteFfiInit();

    databaseFactory = databaseFactoryFfi;
  });

  // ==========================================================
  // EMISSION TEST DATABASE AND REPOSITORY TEST
  // ==========================================================

  test(
    'Emission Test database and repository operations work',
        () async {
      // --------------------------------------------------------
      // CREATE ISOLATED TEST DATABASE
      // --------------------------------------------------------

      final String databasePath =
          '${Directory.systemTemp.path}/sri_guru_emission_test.db';

      final databaseHelper =
      DatabaseHelper.withPath(
        databasePath,
      );

      // --------------------------------------------------------
      // OPEN DATABASE
      // --------------------------------------------------------

      final database =
      await databaseHelper.database;

      // --------------------------------------------------------
      // VERIFY EMISSION TESTS TABLE
      // --------------------------------------------------------

      final tables = await database.rawQuery(
        '''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        AND name = 'emission_tests'
        ''',
      );

      expect(
        tables.length,
        1,
      );

      // --------------------------------------------------------
      // CREATE REPOSITORY USING ISOLATED DATABASE
      // --------------------------------------------------------

      final repository =
      EmissionTestRepository(
        databaseHelper: databaseHelper,
      );

      // ========================================================
      // CREATE EMISSION TEST
      // ========================================================

      final emissionTest = EmissionTest(
        date: DateTime(
          2026,
          9,
          1,
        ),
        name: 'Test Customer',
        vehicleNumber: 'KA03AP3691',
        income: 160.0,

        // ------------------------------------------------------
        // BBTDU ID IS OPTIONAL
        // ------------------------------------------------------

        bbtdUIdNo: null,

        fuelType: 'Diesel',
        paymentMethod: 'G Pay',
      );

      // --------------------------------------------------------
      // INSERT EMISSION TEST
      // --------------------------------------------------------

      final int emissionTestId =
      await repository.addEmissionTest(
        emissionTest,
      );

      // --------------------------------------------------------
      // VERIFY DATABASE GENERATED ID
      // --------------------------------------------------------

      expect(
        emissionTestId,
        greaterThan(0),
      );

      // ========================================================
      // READ ALL EMISSION TESTS
      // ========================================================

      final List<EmissionTest> emissionTests =
      await repository.getEmissionTests();

      // --------------------------------------------------------
      // VERIFY INSERT
      // --------------------------------------------------------

      expect(
        emissionTests.length,
        1,
      );

      expect(
        emissionTests.first.name,
        'Test Customer',
      );

      expect(
        emissionTests.first.vehicleNumber,
        'KA03AP3691',
      );

      expect(
        emissionTests.first.income,
        160.0,
      );

      expect(
        emissionTests.first.bbtdUIdNo,
        isNull,
      );

      expect(
        emissionTests.first.fuelType,
        'Diesel',
      );

      expect(
        emissionTests.first.paymentMethod,
        'G Pay',
      );

      // ========================================================
      // GET EMISSION TEST BY ID
      // ========================================================

      final EmissionTest? emissionTestById =
      await repository.getEmissionTestById(
        emissionTestId,
      );

      // --------------------------------------------------------
      // VERIFY RECORD
      // --------------------------------------------------------

      expect(
        emissionTestById,
        isNotNull,
      );

      expect(
        emissionTestById!.name,
        'Test Customer',
      );

      expect(
        emissionTestById.vehicleNumber,
        'KA03AP3691',
      );

      // ========================================================
      // SEARCH BY CUSTOMER NAME
      // ========================================================

      final List<EmissionTest> nameSearchResults =
      await repository.searchEmissionTests(
        'Test Customer',
      );

      expect(
        nameSearchResults.length,
        1,
      );

      expect(
        nameSearchResults.first.name,
        'Test Customer',
      );

      // ========================================================
      // SEARCH BY VEHICLE NUMBER
      // ========================================================

      final List<EmissionTest> vehicleSearchResults =
      await repository.searchEmissionTests(
        'KA03AP3691',
      );

      expect(
        vehicleSearchResults.length,
        1,
      );

      expect(
        vehicleSearchResults.first.vehicleNumber,
        'KA03AP3691',
      );

      // ========================================================
      // UPDATE EMISSION TEST
      // ========================================================

      final EmissionTest updatedEmissionTest =
      emissionTestById.copyWith(
        name: 'Updated Customer',
        vehicleNumber: 'KA05XY1234',
        income: 200.0,
        bbtdUIdNo: 'BBTDU12345',
        fuelType: 'Petrol',
        paymentMethod: 'Cash',
      );

      // --------------------------------------------------------
      // SAVE UPDATE
      // --------------------------------------------------------

      final int updatedRows =
      await repository.updateEmissionTest(
        updatedEmissionTest,
      );

      expect(
        updatedRows,
        1,
      );

      // --------------------------------------------------------
      // READ UPDATED RECORD
      // --------------------------------------------------------

      final EmissionTest? updatedResult =
      await repository.getEmissionTestById(
        emissionTestId,
      );

      // --------------------------------------------------------
      // VERIFY UPDATED INFORMATION
      // --------------------------------------------------------

      expect(
        updatedResult,
        isNotNull,
      );

      expect(
        updatedResult!.name,
        'Updated Customer',
      );

      expect(
        updatedResult.vehicleNumber,
        'KA05XY1234',
      );

      expect(
        updatedResult.income,
        200.0,
      );

      expect(
        updatedResult.bbtdUIdNo,
        'BBTDU12345',
      );

      expect(
        updatedResult.fuelType,
        'Petrol',
      );

      expect(
        updatedResult.paymentMethod,
        'Cash',
      );

      // ========================================================
      // DELETE EMISSION TEST
      // ========================================================

      final int deletedRows =
      await repository.deleteEmissionTest(
        emissionTestId,
      );

      expect(
        deletedRows,
        1,
      );

      // ========================================================
      // VERIFY DELETION
      // ========================================================

      final EmissionTest? deletedEmissionTest =
      await repository.getEmissionTestById(
        emissionTestId,
      );

      expect(
        deletedEmissionTest,
        isNull,
      );

      // ========================================================
      // CLOSE TEST DATABASE
      // ========================================================

      await databaseHelper.closeDatabase();

      // ========================================================
      // DELETE TEST DATABASE FILE
      // ========================================================

      final File databaseFile =
      File(databasePath);

      if (await databaseFile.exists()) {
        await databaseFile.delete();
      }
    },
  );
}