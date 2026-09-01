// ============================================================
// FILE: customer_repository.dart
//
// PURPOSE:
// Provides all database operations related to customers.
//
// FUNCTIONALITY:
// - Adds customers.
// - Retrieves all customers.
// - Retrieves a customer by ID.
// - Updates customers.
// - Deletes customers.
// - Searches customers.
//
// ARCHITECTURE:
//
// Customer Screen
//       ↓
// CustomerRepository
//       ↓
// DatabaseHelper
//       ↓
// SQLite
// ============================================================

import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';
import '../models/customer.dart';

// ============================================================
// CUSTOMER REPOSITORY
//
// This class is responsible for communicating with the
// customers table in SQLite.
//
// The UI will use this class instead of directly accessing
// SQLite.
// ============================================================

class CustomerRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  //
  // Uses the application's single shared DatabaseHelper.
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper;

  // ============================================================
  // CONSTRUCTOR
  //
  // Allows DatabaseHelper to be supplied to the repository.
  //
  // By default, the application's Singleton instance is used.
  // ============================================================

  CustomerRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  // ============================================================
  // ADD CUSTOMER
  //
  // Inserts a new customer into the customers table.
  //
  // Returns:
  // The newly created customer's database ID.
  // ============================================================

  Future<int> addCustomer(Customer customer) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // INSERT CUSTOMER
    //
    // Customer.toMap() converts the Dart object into the Map
    // format required by SQLite.
    //
    // The ID is removed because SQLite generates it
    // automatically.
    // ----------------------------------------------------------

    final Map<String, dynamic> customerData =
    customer.toMap();

    customerData.remove('id');

    return database.insert(
      'customers',
      customerData,
    );
  }

  // ============================================================
  // GET ALL CUSTOMERS
  //
  // Retrieves every customer from the database.
  //
  // Customers are returned in newest-first order.
  // ============================================================

  Future<List<Customer>> getCustomers() async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // QUERY CUSTOMERS
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'customers',
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT DATABASE ROWS TO CUSTOMER OBJECTS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          Customer.fromMap(row),
    )
        .toList();
  }

  // ============================================================
  // GET CUSTOMER BY ID
  //
  // Retrieves one customer using the internal SQLite ID.
  //
  // Returns null if the customer does not exist.
  // ============================================================

  Future<Customer?> getCustomerById(int id) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // FIND CUSTOMER
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    // ----------------------------------------------------------
    // CUSTOMER NOT FOUND
    // ----------------------------------------------------------

    if (rows.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // RETURN CUSTOMER
    // ----------------------------------------------------------

    return Customer.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // UPDATE CUSTOMER
  //
  // Updates an existing customer.
  //
  // Returns:
  // Number of rows updated.
  // ============================================================

  Future<int> updateCustomer(Customer customer) async {
    // ----------------------------------------------------------
    // CUSTOMER MUST HAVE AN ID
    //
    // An existing customer needs an ID so SQLite knows which
    // record should be updated.
    // ----------------------------------------------------------

    if (customer.id == null) {
      throw ArgumentError(
        'Customer ID is required when updating a customer.',
      );
    }

    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // PREPARE CUSTOMER DATA
    //
    // We don't update the primary key.
    // ----------------------------------------------------------

    final Map<String, dynamic> customerData =
    customer.toMap();

    customerData.remove('id');

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------

    return database.update(
      'customers',
      customerData,
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // ============================================================
  // DELETE CUSTOMER
  //
  // Deletes a customer using the internal database ID.
  //
  // Returns:
  // Number of rows deleted.
  // ============================================================

  Future<int> deleteCustomer(int id) async {
    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // DELETE CUSTOMER
    // ----------------------------------------------------------

    return database.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // SEARCH CUSTOMERS
  //
  // Searches customers by:
  //
  // - Customer name
  // - Customer number/contact number
  //
  // The search is case-insensitive for the name.
  // ============================================================

  Future<List<Customer>> searchCustomers(
      String searchText,
      ) async {
    // ----------------------------------------------------------
    // REMOVE UNNECESSARY SPACES
    // ----------------------------------------------------------

    final String search =
    searchText.trim();

    // ----------------------------------------------------------
    // IF SEARCH IS EMPTY
    //
    // Return all customers instead of executing a pointless
    // search query.
    // ----------------------------------------------------------

    if (search.isEmpty) {
      return getCustomers();
    }

    // ----------------------------------------------------------
    // GET DATABASE
    // ----------------------------------------------------------

    final Database database =
    await _databaseHelper.database;

    // ----------------------------------------------------------
    // SEARCH DATABASE
    //
    // The % symbols allow partial matching.
    //
    // Example:
    //
    // Searching "San"
    //
    // can find:
    //
    // Santhosh Kumar
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> rows =
    await database.query(
      'customers',
      where: '''
        name LIKE ?
        OR phone LIKE ?
        OR alternate_phone LIKE ?
      ''',
      whereArgs: [
        '%$search%',
        '%$search%',
        '%$search%',
      ],
      orderBy: 'id DESC',
    );

    // ----------------------------------------------------------
    // CONVERT RESULTS TO CUSTOMER OBJECTS
    // ----------------------------------------------------------

    return rows
        .map(
          (Map<String, dynamic> row) =>
          Customer.fromMap(row),
    )
        .toList();
  }
}