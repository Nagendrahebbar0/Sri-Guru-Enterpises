// ============================================================
// FILE: alignment_bill_repository.dart
//
// PURPOSE:
// Handles all SQLite database operations for Simple Alignment
// Bills.
//
// This repository keeps database logic separate from the UI.
//
// Alignment Billing does NOT use GST.
// ============================================================

import '../core/database/database_helper.dart';
import '../models/alignment_bill.dart';

class AlignmentBillRepository {
  // ------------------------------------------------------------
  // DATABASE HELPER
  // ------------------------------------------------------------

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // ============================================================
  // ADD BILL
  // ============================================================

  /// Adds a new Alignment Bill to SQLite.
  Future<int> addBill(AlignmentBill bill) async {
    final db = await _databaseHelper.database;

    return db.insert(
      'alignment_bills',
      bill.toMap(),
    );
  }

  // ============================================================
  // GET ALL BILLS
  // ============================================================

  /// Returns all Alignment Bills.
  ///
  /// Newest bills are returned first.
  Future<List<AlignmentBill>> getAllBills() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'alignment_bills',
      orderBy: 'date DESC, id DESC',
    );

    return maps
        .map(AlignmentBill.fromMap)
        .toList();
  }

  // ============================================================
  // GET BILL BY ID
  // ============================================================

  /// Returns one Alignment Bill using its database ID.
  Future<AlignmentBill?> getBillById(int id) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'alignment_bills',
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return AlignmentBill.fromMap(maps.first);
  }

  // ============================================================
  // SEARCH BILLS
  // ============================================================

  /// Searches Alignment Bills.
  ///
  /// Search is performed against:
  /// - Bill Number
  /// - Customer Name
  /// - Customer Number
  /// - Vehicle Number
  /// - Service
  Future<List<AlignmentBill>> searchBills(String query) async {
    final db = await _databaseHelper.database;

    final String searchText = query.trim();

    if (searchText.isEmpty) {
      return getAllBills();
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'alignment_bills',
      where: '''
        bill_number LIKE ?
        OR customer_name LIKE ?
        OR customer_number LIKE ?
        OR vehicle_number LIKE ?
        OR service LIKE ?
      ''',
      whereArgs: <Object>[
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
        '%$searchText%',
      ],
      orderBy: 'date DESC, id DESC',
    );

    return maps
        .map(AlignmentBill.fromMap)
        .toList();
  }

  // ============================================================
  // UPDATE BILL
  // ============================================================

  /// Updates an existing Alignment Bill.
  ///
  /// The existing bill number is preserved unless the supplied
  /// AlignmentBill contains a different one.
  Future<int> updateBill(AlignmentBill bill) async {
    if (bill.id == null) {
      throw ArgumentError(
        'Cannot update an Alignment Bill without an ID.',
      );
    }

    final db = await _databaseHelper.database;

    return db.update(
      'alignment_bills',
      bill.toMap(),
      where: 'id = ?',
      whereArgs: <Object>[bill.id!],
    );
  }

  // ============================================================
  // DELETE BILL
  // ============================================================

  /// Deletes an Alignment Bill using its database ID.
  Future<int> deleteBill(int id) async {
    final db = await _databaseHelper.database;

    return db.delete(
      'alignment_bills',
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  // ============================================================
  // CHECK BILL NUMBER
  // ============================================================

  /// Checks whether a bill number already exists.
  ///
  /// Returns true when the number is already present.
  Future<bool> billNumberExists(
      String billNumber, {
        int? excludeId,
      }) async {
    final db = await _databaseHelper.database;

    String where = 'bill_number = ?';
    final List<Object> whereArgs = <Object>[billNumber];

    // During editing, the current bill itself should not
    // be treated as a duplicate.
    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final List<Map<String, dynamic>> result = await db.query(
      'alignment_bills',
      columns: <String>['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ============================================================
  // GET LAST BILL
  // ============================================================

  /// Returns the most recently created Alignment Bill.
  Future<AlignmentBill?> getLastBill() async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'alignment_bills',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return AlignmentBill.fromMap(maps.first);
  }

  // ============================================================
  // GENERATE NEXT BILL NUMBER
  // ============================================================
  //
  // The first bill number is entered manually by the user.
  //
  // Example:
  //
  // First bill:
  // AL001
  //
  // Next:
  // AL002
  //
  // Next:
  // AL003
  //
  // The repository increments the numeric ending while
  // preserving the prefix.
  // ============================================================

  Future<String?> generateNextBillNumber() async {
    final AlignmentBill? lastBill = await getLastBill();

    if (lastBill == null) {
      // There is no previous bill.
      //
      // The first bill number must be entered manually.
      return null;
    }

    final String lastNumber = lastBill.billNumber.trim();

    // Find the numeric portion at the end of the bill number.
    final RegExpMatch? match =
    RegExp(r'^(.*?)(\d+)$').firstMatch(lastNumber);

    if (match == null) {
      // If the previous bill does not end with a number,
      // automatic numbering cannot safely be performed.
      return null;
    }

    final String prefix = match.group(1) ?? '';
    final String numberText = match.group(2) ?? '';

    final int? number = int.tryParse(numberText);

    if (number == null) {
      return null;
    }

    final int nextNumber = number + 1;

    // Preserve the same number of digits used by the
    // previous bill number.
    final String nextNumberText =
    nextNumber.toString().padLeft(
      numberText.length,
      '0',
    );

    return '$prefix$nextNumberText';
  }

  // ============================================================
  // DUPLICATE BILL
  // ============================================================

  /// Creates a duplicate of an existing Alignment Bill.
  ///
  /// The duplicated bill:
  /// - Gets a new database ID.
  /// - Gets a new bill number when possible.
  /// - Gets a new creation timestamp.
  /// - Keeps customer, vehicle and service details.
  Future<int> duplicateBill(AlignmentBill bill) async {
    final String? nextBillNumber =
    await generateNextBillNumber();

    if (nextBillNumber == null) {
      throw StateError(
        'Unable to generate the next Alignment Bill number.',
      );
    }

    final DateTime now = DateTime.now();

    final AlignmentBill duplicate = bill.copyWith(
      id: null,
      billNumber: nextBillNumber,
      createdAt: now,
      updatedAt: now,
    );

    return addBill(duplicate);
  }
}