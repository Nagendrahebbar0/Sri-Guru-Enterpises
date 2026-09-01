import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sri_guru_enterprise/core/database/database_helper.dart';
import 'package:sri_guru_enterprise/models/customer.dart';
import 'package:sri_guru_enterprise/repositories/customer_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'Customer database and repository CRUD operations work',
        () async {
      final String databasePath =
          '${Directory.systemTemp.path}/sri_guru_customer_test.db';

      final databaseHelper =
      DatabaseHelper.withPath(databasePath);

      final database =
      await databaseHelper.database;

      // --------------------------------------------------------
      // VERIFY CUSTOMERS TABLE
      // --------------------------------------------------------

      final tables = await database.rawQuery(
        '''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        AND name = 'customers'
        ''',
      );

      expect(tables.length, 1);

      // --------------------------------------------------------
      // CREATE REPOSITORY USING ISOLATED DATABASE
      // --------------------------------------------------------

      final repository = CustomerRepository(
        databaseHelper: databaseHelper,
      );

      // --------------------------------------------------------
      // ADD CUSTOMER
      // --------------------------------------------------------

      final customer = Customer(
        name: 'Test Customer',
        phone: '9999999999',
        alternatePhone: '8888888888',
        address: 'Bangalore',
        remarks: 'Repository test customer',
      );

      final int customerId =
      await repository.addCustomer(customer);

      expect(customerId, greaterThan(0));

      // --------------------------------------------------------
      // GET ALL CUSTOMERS
      // --------------------------------------------------------

      final List<Customer> customers =
      await repository.getCustomers();

      expect(customers.length, 1);
      expect(customers.first.name, 'Test Customer');
      expect(customers.first.phone, '9999999999');

      // --------------------------------------------------------
      // GET CUSTOMER BY ID
      // --------------------------------------------------------

      final Customer? customerById =
      await repository.getCustomerById(
        customerId,
      );

      expect(customerById, isNotNull);
      expect(customerById!.name, 'Test Customer');
      expect(customerById.phone, '9999999999');

      // --------------------------------------------------------
      // SEARCH BY NAME
      // --------------------------------------------------------

      final List<Customer> searchResults =
      await repository.searchCustomers(
        'Test Customer',
      );

      expect(searchResults.length, 1);

      // --------------------------------------------------------
      // SEARCH BY PHONE
      // --------------------------------------------------------

      final List<Customer> phoneSearchResults =
      await repository.searchCustomers(
        '9999999999',
      );

      expect(phoneSearchResults.length, 1);

      // --------------------------------------------------------
      // UPDATE CUSTOMER
      // --------------------------------------------------------

      final Customer updatedCustomer =
      customerById.copyWith(
        name: 'Updated Customer',
        address: 'Mysore',
      );

      final int updatedRows =
      await repository.updateCustomer(
        updatedCustomer,
      );

      expect(updatedRows, 1);

      // --------------------------------------------------------
      // VERIFY UPDATE
      // --------------------------------------------------------

      final Customer? updatedResult =
      await repository.getCustomerById(
        customerId,
      );

      expect(updatedResult, isNotNull);
      expect(updatedResult!.name, 'Updated Customer');
      expect(updatedResult.address, 'Mysore');

      // --------------------------------------------------------
      // DELETE CUSTOMER
      // --------------------------------------------------------

      final int deletedRows =
      await repository.deleteCustomer(
        customerId,
      );

      expect(deletedRows, 1);

      // --------------------------------------------------------
      // VERIFY DELETION
      // --------------------------------------------------------

      final Customer? deletedCustomer =
      await repository.getCustomerById(
        customerId,
      );

      expect(deletedCustomer, isNull);

      // --------------------------------------------------------
      // CLOSE TEST DATABASE
      // --------------------------------------------------------

      await databaseHelper.closeDatabase();

      // --------------------------------------------------------
      // REMOVE TEST DATABASE FILE
      // --------------------------------------------------------

      final File databaseFile =
      File(databasePath);

      if (await databaseFile.exists()) {
        await databaseFile.delete();
      }
    },
  );
}