// ============================================================
// FILE: fleet_service_repository_test.dart
//
// PURPOSE:
// Tests the Fleet Service database and repository functionality.
//
// FUNCTIONALITY TESTED:
// - Fleet Services table creation.
// - Add Fleet Service.
// - Read Fleet Services.
// - Get Fleet Service by ID.
// - Search Fleet Services.
// - Update Fleet Service.
// - Delete Fleet Service.
// - Verify Fleet Service deletion.
//
// IMPORTANT:
// A separate temporary SQLite database is used for this test.
// This prevents the Fleet test from interfering with the
// Customer and Emission tests.
// ============================================================

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sri_guru_enterprise/core/database/database_helper.dart';
import 'package:sri_guru_enterprise/models/fleet_service.dart';
import 'package:sri_guru_enterprise/repositories/fleet_service_repository.dart';

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
  // FLEET SERVICE DATABASE AND REPOSITORY TEST
  // ==========================================================

  test(
    'Fleet Service database and repository operations work',
        () async {
      // --------------------------------------------------------
      // CREATE ISOLATED TEST DATABASE
      // --------------------------------------------------------

      final String databasePath =
          '${Directory.systemTemp.path}/sri_guru_fleet_test.db';

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
      // VERIFY FLEET SERVICES TABLE
      // --------------------------------------------------------

      final tables = await database.rawQuery(
        '''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        AND name = 'fleet_services'
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
      FleetServiceRepository(
        databaseHelper: databaseHelper,
      );

      // ========================================================
      // CREATE FLEET SERVICE
      // ========================================================

      final fleetService = FleetService(
        date: DateTime(
          2026,
          9,
          1,
        ),
        vehicleBrand: 'Toyota',
        vehicleType: 'Etios',
        vehicleNumber: 'KA03AP3691',
        customerNumber: '9999999999',
        odometer: 125430,
        workDone: 'Oil Change',
        totalCount: 1,
      );

      // --------------------------------------------------------
      // INSERT FLEET SERVICE
      // --------------------------------------------------------

      final int fleetServiceId =
      await repository.addFleetService(
        fleetService,
      );

      // --------------------------------------------------------
      // VERIFY DATABASE GENERATED ID
      // --------------------------------------------------------

      expect(
        fleetServiceId,
        greaterThan(0),
      );

      // ========================================================
      // READ ALL FLEET SERVICES
      // ========================================================

      final List<FleetService> services =
      await repository.getFleetServices();

      // --------------------------------------------------------
      // VERIFY INSERT
      // --------------------------------------------------------

      expect(
        services.length,
        1,
      );

      expect(
        services.first.vehicleBrand,
        'Toyota',
      );

      expect(
        services.first.vehicleType,
        'Etios',
      );

      expect(
        services.first.vehicleNumber,
        'KA03AP3691',
      );

      expect(
        services.first.customerNumber,
        '9999999999',
      );

      expect(
        services.first.odometer,
        125430,
      );

      expect(
        services.first.workDone,
        'Oil Change',
      );

      // ========================================================
      // GET FLEET SERVICE BY ID
      // ========================================================

      final FleetService? serviceById =
      await repository.getFleetServiceById(
        fleetServiceId,
      );

      // --------------------------------------------------------
      // VERIFY SERVICE
      // --------------------------------------------------------

      expect(
        serviceById,
        isNotNull,
      );

      expect(
        serviceById!.vehicleBrand,
        'Toyota',
      );

      expect(
        serviceById.vehicleType,
        'Etios',
      );

      expect(
        serviceById.vehicleNumber,
        'KA03AP3691',
      );

      // ========================================================
      // SEARCH FLEET SERVICE
      // ========================================================

      final List<FleetService> searchResults =
      await repository.searchFleetServices(
        'KA03AP3691',
      );

      expect(
        searchResults.length,
        1,
      );

      expect(
        searchResults.first.vehicleNumber,
        'KA03AP3691',
      );

      // --------------------------------------------------------
      // SEARCH BY CUSTOMER NUMBER
      // --------------------------------------------------------

      final List<FleetService> customerSearchResults =
      await repository.searchFleetServices(
        '9999999999',
      );

      expect(
        customerSearchResults.length,
        1,
      );

      // ========================================================
      // UPDATE FLEET SERVICE
      // ========================================================

      final FleetService updatedFleetService =
      serviceById.copyWith(
        vehicleType: 'Innova Crysta',
        odometer: 130000,
        workDone: 'Full Service',
      );

      // --------------------------------------------------------
      // SAVE UPDATED SERVICE
      // --------------------------------------------------------

      final int updatedRows =
      await repository.updateFleetService(
        updatedFleetService,
      );

      expect(
        updatedRows,
        1,
      );

      // --------------------------------------------------------
      // READ UPDATED SERVICE
      // --------------------------------------------------------

      final FleetService? updatedResult =
      await repository.getFleetServiceById(
        fleetServiceId,
      );

      // --------------------------------------------------------
      // VERIFY UPDATED INFORMATION
      // --------------------------------------------------------

      expect(
        updatedResult,
        isNotNull,
      );

      expect(
        updatedResult!.vehicleType,
        'Innova Crysta',
      );

      expect(
        updatedResult.odometer,
        130000,
      );

      expect(
        updatedResult.workDone,
        'Full Service',
      );

      // ========================================================
      // DELETE FLEET SERVICE
      // ========================================================

      final int deletedRows =
      await repository.deleteFleetService(
        fleetServiceId,
      );

      expect(
        deletedRows,
        1,
      );

      // ========================================================
      // VERIFY SERVICE NO LONGER EXISTS
      // ========================================================

      final FleetService? deletedService =
      await repository.getFleetServiceById(
        fleetServiceId,
      );

      expect(
        deletedService,
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