import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/tyre_bill.dart';
import '../models/tyre_bill_item.dart';

/// Repository for Tyre Billing.
///
/// This repository handles:
/// - Bill CRUD.
/// - Bill item CRUD.
/// - Invoice number generation.
/// - Customer/bill searching.
/// - Tyre stock deduction and restoration.
/// - Transaction-safe create, edit, duplicate and delete.
///
/// IMPORTANT:
/// Existing Tyre Stock repository is not modified.
/// Stock is accessed directly inside SQLite transactions so that
/// bill changes and stock changes succeed or fail together.
class TyreBillRepository {
  final DatabaseHelper _databaseHelper;

  TyreBillRepository({
    DatabaseHelper? databaseHelper,
  }) : _databaseHelper =
      databaseHelper ?? DatabaseHelper.instance;

  static const String _billsTable = 'tyre_bills';
  static const String _itemsTable = 'tyre_bill_items';
  static const String _stockTable = 'tyre_stocks';

  // ============================================================
  // BILL QUERIES
  // ============================================================

  /// Returns all tyre bills, newest first.
  Future<List<TyreBill>> getAllBills() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      _billsTable,
      orderBy: 'id DESC',
    );

    return maps.map(TyreBill.fromMap).toList();
  }

  /// Returns one bill by ID.
  Future<TyreBill?> getBillById(int id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      _billsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TyreBill.fromMap(maps.first);
  }

  /// Returns one bill by invoice number.
  Future<TyreBill?> getBillByInvoiceNumber(
      String invoiceNumber,
      ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      _billsTable,
      where: 'invoice_number = ?',
      whereArgs: [invoiceNumber.trim()],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return TyreBill.fromMap(maps.first);
  }

  /// Searches by:
  /// - Invoice Number
  /// - Customer Name
  /// - Customer Number
  /// - Vehicle Number
  Future<List<TyreBill>> searchBills(
      String searchText,
      ) async {
    final String query = searchText.trim();

    if (query.isEmpty) {
      return getAllBills();
    }

    final Database db = await _databaseHelper.database;
    final String pattern = '%$query%';

    final List<Map<String, dynamic>> maps = await db.query(
      _billsTable,
      where: '''
        invoice_number LIKE ?
        OR customer_name LIKE ?
        OR customer_number LIKE ?
        OR vehicle_number LIKE ?
      ''',
      whereArgs: [
        pattern,
        pattern,
        pattern,
        pattern,
      ],
      orderBy: 'id DESC',
    );

    return maps.map(TyreBill.fromMap).toList();
  }

  // ============================================================
  // BILL ITEMS
  // ============================================================

  /// Returns all items for a bill.
  Future<List<TyreBillItem>> getItemsForBill(
      int billId,
      ) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      _itemsTable,
      where: 'bill_id = ?',
      whereArgs: [billId],
      orderBy: 'id ASC',
    );

    return maps.map(TyreBillItem.fromMap).toList();
  }

  /// Returns bill and its items together.
  Future<TyreBillWithItems?> getBillWithItems(
      int billId,
      ) async {
    final TyreBill? bill = await getBillById(billId);

    if (bill == null) {
      return null;
    }

    final List<TyreBillItem> items =
    await getItemsForBill(billId);

    return TyreBillWithItems(
      bill: bill,
      items: items,
    );
  }

  // ============================================================
  // INVOICE NUMBER
  // ============================================================

  /// Checks whether an invoice number already exists.
  Future<bool> invoiceNumberExists(
      String invoiceNumber, {
        int? excludeBillId,
      }) async {
    final Database db = await _databaseHelper.database;

    String where = 'invoice_number = ?';

    final List<Object?> whereArgs = [
      invoiceNumber.trim(),
    ];

    if (excludeBillId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeBillId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _billsTable,
      columns: ['id'],
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return maps.isNotEmpty;
  }

  /// Validates the manually entered first invoice number.
  Future<void> validateNewInvoiceNumber(
      String invoiceNumber,
      ) async {
    final String number = invoiceNumber.trim();

    if (number.isEmpty) {
      throw ArgumentError(
        'Invoice number cannot be empty.',
      );
    }

    final bool exists =
    await invoiceNumberExists(number);

    if (exists) {
      throw StateError(
        'Invoice number $number already exists.',
      );
    }
  }

  /// Generates the next INV invoice number.
  ///
  /// Example:
  /// INV125 -> INV126
  /// INV126 -> INV127
  ///
  /// Leading zero padding is not added.
  Future<String> generateNextInvoiceNumber() async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps =
    await db.query(
      _billsTable,
      columns: ['invoice_number'],
    );

    int? highestNumber;

    for (final Map<String, dynamic> map in maps) {
      final String invoiceNumber =
          map['invoice_number']?.toString().trim() ?? '';

      final int? number =
      _extractInvoiceNumber(invoiceNumber);

      if (number == null) {
        continue;
      }

      if (highestNumber == null ||
          number > highestNumber) {
        highestNumber = number;
      }
    }

    if (highestNumber == null) {
      throw StateError(
        'The first invoice number must be entered manually.',
      );
    }

    return 'INV${highestNumber + 1}';
  }

  /// Extracts the numeric part from INV125.
  int? _extractInvoiceNumber(
      String invoiceNumber,
      ) {
    final RegExp regex = RegExp(
      r'^INV(\d+)$',
      caseSensitive: false,
    );

    final Match? match =
    regex.firstMatch(invoiceNumber);

    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  // ============================================================
  // CREATE BILL + DEDUCT STOCK
  // ============================================================

  /// Creates a bill and deducts the required tyre stock.
  ///
  /// Everything happens inside one SQLite transaction.
  ///
  /// If stock is insufficient or any database operation fails,
  /// the complete operation is rolled back.
  Future<int> insertBill({
    required TyreBill bill,
    required List<TyreBillItem> items,
  }) async {
    _validateBill(bill);
    _validateItems(items);

    final Database db = await _databaseHelper.database;

    return db.transaction<int>((txn) async {
      // Check invoice uniqueness inside the transaction.
      final List<Map<String, dynamic>> existing =
      await txn.query(
        _billsTable,
        columns: ['id'],
        where: 'invoice_number = ?',
        whereArgs: [bill.invoiceNumber.trim()],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw StateError(
          'Invoice number ${bill.invoiceNumber} already exists.',
        );
      }

      // Calculate total quantities for each stock record.
      final Map<int, int> quantities =
      _groupStockQuantities(items);

      // Check stock BEFORE changing anything.
      await _validateAvailableStock(
        txn,
        quantities,
      );

      // Deduct stock.
      await _changeStock(
        txn,
        quantities,
        multiplier: -1,
      );

      // Insert main bill.
      final int billId = await txn.insert(
        _billsTable,
        bill.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Insert bill items.
      for (final TyreBillItem item in items) {
        final TyreBillItem itemWithBillId =
        item.copyWith(
          billId: billId,
          amount: TyreBillItem.calculateAmount(
            item.quantity,
            item.rate,
          ),
        );

        await txn.insert(
          _itemsTable,
          itemWithBillId.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      return billId;
    });
  }

  // ============================================================
  // UPDATE BILL + STOCK ADJUSTMENT
  // ============================================================

  /// Updates a bill and adjusts stock according to the difference.
  ///
  /// Example:
  ///
  /// Old quantity = 4
  /// New quantity = 6
  /// Stock change = -2
  ///
  /// Old quantity = 6
  /// New quantity = 4
  /// Stock change = +2
  Future<void> updateBill({
    required TyreBill bill,
    required List<TyreBillItem> items,
  }) async {
    if (bill.id == null) {
      throw ArgumentError(
        'Cannot update a bill without an ID.',
      );
    }

    _validateBill(bill);
    _validateItems(items);

    final Database db = await _databaseHelper.database;

    await db.transaction<void>((txn) async {
      // Get the existing bill.
      final List<Map<String, dynamic>> existingBillRows =
      await txn.query(
        _billsTable,
        where: 'id = ?',
        whereArgs: [bill.id],
        limit: 1,
      );

      if (existingBillRows.isEmpty) {
        throw StateError(
          'The bill could not be found.',
        );
      }

      final TyreBill existingBill =
      TyreBill.fromMap(existingBillRows.first);

      // Invoice number must never change during editing.
      if (existingBill.invoiceNumber !=
          bill.invoiceNumber.trim()) {
        throw StateError(
          'Invoice number cannot be changed while editing a bill.',
        );
      }

      // Check whether another bill uses this invoice number.
      final List<Map<String, dynamic>> duplicateRows =
      await txn.query(
        _billsTable,
        columns: ['id'],
        where: '''
          invoice_number = ?
          AND id != ?
        ''',
        whereArgs: [
          bill.invoiceNumber.trim(),
          bill.id,
        ],
        limit: 1,
      );

      if (duplicateRows.isNotEmpty) {
        throw StateError(
          'Invoice number ${bill.invoiceNumber} already exists.',
        );
      }

      // Load old items.
      final List<Map<String, dynamic>> oldItemRows =
      await txn.query(
        _itemsTable,
        where: 'bill_id = ?',
        whereArgs: [bill.id],
      );

      final List<TyreBillItem> oldItems =
      oldItemRows
          .map(TyreBillItem.fromMap)
          .toList();

      final Map<int, int> oldQuantities =
      _groupStockQuantities(oldItems);

      final Map<int, int> newQuantities =
      _groupStockQuantities(items);

      // Calculate the net stock change.
      final Map<int, int> stockChanges =
      _calculateStockDifference(
        oldQuantities,
        newQuantities,
      );

      // Only positive stock deductions need availability checking.
      final Map<int, int> deductions = {};

      for (final MapEntry<int, int> entry
      in stockChanges.entries) {
        if (entry.value < 0) {
          deductions[entry.key] =
          -entry.value;
        }
      }

      // Check that newly required stock exists.
      await _validateAvailableStock(
        txn,
        deductions,
      );

      // Apply the net stock adjustment.
      await _changeStock(
        txn,
        stockChanges,
        multiplier: 1,
      );

      // Update main bill.
      await txn.update(
        _billsTable,
        bill.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [bill.id],
      );

      // Replace old item records.
      await txn.delete(
        _itemsTable,
        where: 'bill_id = ?',
        whereArgs: [bill.id],
      );

      for (final TyreBillItem item in items) {
        final TyreBillItem itemWithBillId =
        item.copyWith(
          billId: bill.id,
          amount: TyreBillItem.calculateAmount(
            item.quantity,
            item.rate,
          ),
        );

        await txn.insert(
          _itemsTable,
          itemWithBillId.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  // ============================================================
  // DELETE BILL + RESTORE STOCK
  // ============================================================

  /// Deletes a bill and restores all quantities previously sold.
  ///
  /// Bill deletion and stock restoration happen inside the same
  /// SQLite transaction.
  Future<void> deleteBill(int billId) async {
    final Database db = await _databaseHelper.database;

    await db.transaction<void>((txn) async {
      final List<Map<String, dynamic>> billRows =
      await txn.query(
        _billsTable,
        where: 'id = ?',
        whereArgs: [billId],
        limit: 1,
      );

      if (billRows.isEmpty) {
        throw StateError(
          'The bill could not be found.',
        );
      }

      final List<Map<String, dynamic>> itemRows =
      await txn.query(
        _itemsTable,
        where: 'bill_id = ?',
        whereArgs: [billId],
      );

      final List<TyreBillItem> items =
      itemRows
          .map(TyreBillItem.fromMap)
          .toList();

      final Map<int, int> quantities =
      _groupStockQuantities(items);

      // Restore sold quantities.
      await _changeStock(
        txn,
        quantities,
        multiplier: 1,
      );

      // Delete items.
      await txn.delete(
        _itemsTable,
        where: 'bill_id = ?',
        whereArgs: [billId],
      );

      // Delete bill.
      await txn.delete(
        _billsTable,
        where: 'id = ?',
        whereArgs: [billId],
      );
    });
  }

  // ============================================================
  // DUPLICATE BILL
  // ============================================================

  /// Duplicates an existing bill.
  ///
  /// The duplicate:
  /// - Gets a new database ID.
  /// - Gets the next invoice number.
  /// - Copies customer information.
  /// - Copies all tyre items.
  /// - Deducts stock again.
  Future<int> duplicateBill(int billId) async {
    final TyreBillWithItems? original =
    await getBillWithItems(billId);

    if (original == null) {
      throw StateError(
        'The bill to duplicate was not found.',
      );
    }

    final String newInvoiceNumber =
    await generateNextInvoiceNumber();

    final DateTime now = DateTime.now();

    final TyreBill duplicatedBill =
    original.bill.copyWith(
      id: null,
      invoiceNumber: newInvoiceNumber,
      date: now,
      createdAt: now,
      updatedAt: now,
    );

    final List<TyreBillItem> duplicatedItems =
    original.items
        .map(
          (TyreBillItem item) => item.copyWith(
        id: null,
        billId: null,
      ),
    )
        .toList();

    return insertBill(
      bill: duplicatedBill,
      items: duplicatedItems,
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  /// Validates bill-level fields.
  void _validateBill(TyreBill bill) {
    if (bill.invoiceNumber.trim().isEmpty) {
      throw ArgumentError(
        'Invoice number cannot be empty.',
      );
    }

    if (bill.customerName.trim().isEmpty) {
      throw ArgumentError(
        'Customer name cannot be empty.',
      );
    }

    if (bill.customerNumber.trim().isEmpty) {
      throw ArgumentError(
        'Customer number cannot be empty.',
      );
    }

    if (bill.vehicleNumber.trim().isEmpty) {
      throw ArgumentError(
        'Vehicle number cannot be empty.',
      );
    }

    if (bill.paymentMethod != 'Cash' &&
        bill.paymentMethod != 'G Pay') {
      throw ArgumentError(
        'Payment method must be Cash or G Pay.',
      );
    }

    if (bill.billType != 'GST Invoice' &&
        bill.billType != 'Non-GST Invoice') {
      throw ArgumentError(
        'Bill type must be GST Invoice or Non-GST Invoice.',
      );
    }

    // GST Invoice must have a GST invoice number.
    if (bill.billType == 'GST Invoice' &&
        (bill.gstInvoiceNumber == null ||
            bill.gstInvoiceNumber!.trim().isEmpty)) {
      throw ArgumentError(
        'GST Invoice Number is required for a GST Invoice.',
      );
    }
  }

  /// Validates all tyre items.
  void _validateItems(
      List<TyreBillItem> items,
      ) {
    if (items.isEmpty) {
      throw ArgumentError(
        'A tyre bill must contain at least one item.',
      );
    }

    for (final TyreBillItem item in items) {
      if (item.tyreStockId <= 0) {
        throw ArgumentError(
          'Every tyre item must reference a valid stock item.',
        );
      }

      if (item.quantity <= 0) {
        throw ArgumentError(
          'Tyre quantity must be greater than zero.',
        );
      }

      // Existing tyre stock stores stock as INTEGER.
      // Therefore billing quantity must be a whole number.
      if (item.quantity !=
          item.quantity.roundToDouble()) {
        throw ArgumentError(
          'Tyre quantity must be a whole number.',
        );
      }

      if (item.rate < 0) {
        throw ArgumentError(
          'Tyre rate cannot be negative.',
        );
      }
    }
  }

  // ============================================================
  // STOCK HELPERS
  // ============================================================

  /// Groups quantities by tyre stock ID.
  ///
  /// If the same stock item appears twice in an invoice:
  ///
  /// Item 1 = 2
  /// Item 2 = 3
  ///
  /// Total deduction = 5.
  Map<int, int> _groupStockQuantities(
      List<TyreBillItem> items,
      ) {
    final Map<int, int> quantities = {};

    for (final TyreBillItem item in items) {
      final int quantity =
      item.quantity.round();

      quantities[item.tyreStockId] =
          (quantities[item.tyreStockId] ?? 0) +
              quantity;
    }

    return quantities;
  }

  /// Calculates new stock requirement relative to old bill.
  ///
  /// Negative value = deduct stock.
  /// Positive value = restore stock.
  Map<int, int> _calculateStockDifference(
      Map<int, int> oldQuantities,
      Map<int, int> newQuantities,
      ) {
    final Set<int> stockIds = {
      ...oldQuantities.keys,
      ...newQuantities.keys,
    };

    final Map<int, int> changes = {};

    for (final int stockId in stockIds) {
      final int oldQuantity =
          oldQuantities[stockId] ?? 0;

      final int newQuantity =
          newQuantities[stockId] ?? 0;

      final int change =
          oldQuantity - newQuantity;

      if (change != 0) {
        changes[stockId] = change;
      }
    }

    return changes;
  }

  /// Checks whether sufficient stock exists.
  Future<void> _validateAvailableStock(
      Transaction txn,
      Map<int, int> quantities,
      ) async {
    for (final MapEntry<int, int> entry
    in quantities.entries) {
      final int stockId = entry.key;
      final int requiredQuantity = entry.value;

      if (requiredQuantity <= 0) {
        continue;
      }

      final List<Map<String, dynamic>> rows =
      await txn.query(
        _stockTable,
        columns: [
          'id',
          'stock',
          'tyre',
          'pattern',
          'size',
        ],
        where: 'id = ?',
        whereArgs: [stockId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw StateError(
          'Tyre stock item $stockId was not found.',
        );
      }

      final int currentStock =
      _toInt(rows.first['stock']);

      if (currentStock < requiredQuantity) {
        final String tyre =
            rows.first['tyre']?.toString() ?? '';

        final String pattern =
            rows.first['pattern']?.toString() ?? '';

        final String size =
            rows.first['size']?.toString() ?? '';

        throw StateError(
          'Insufficient stock for '
              '$tyre $pattern $size. '
              'Available: $currentStock, '
              'Required: $requiredQuantity.',
        );
      }
    }
  }

  /// Changes stock quantities.
  ///
  /// multiplier:
  /// - -1 = deduct
  /// - +1 = restore
  Future<void> _changeStock(
      Transaction txn,
      Map<int, int> quantities, {
        required int multiplier,
      }) async {
    for (final MapEntry<int, int> entry
    in quantities.entries) {
      final int stockId = entry.key;
      final int quantity =
          entry.value * multiplier;

      if (quantity == 0) {
        continue;
      }

      final List<Map<String, dynamic>> rows =
      await txn.query(
        _stockTable,
        columns: ['stock'],
        where: 'id = ?',
        whereArgs: [stockId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw StateError(
          'Tyre stock item $stockId was not found.',
        );
      }

      final int currentStock =
      _toInt(rows.first['stock']);

      final int newStock =
          currentStock + quantity;

      if (newStock < 0) {
        throw StateError(
          'Stock cannot become negative.',
        );
      }

      await txn.update(
        _stockTable,
        {
          'stock': newStock,
        },
        where: 'id = ?',
        whereArgs: [stockId],
      );
    }
  }

  /// Safely converts SQLite values to int.
  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}

/// Combines a Tyre Bill with all of its items.
class TyreBillWithItems {
  final TyreBill bill;
  final List<TyreBillItem> items;

  const TyreBillWithItems({
    required this.bill,
    required this.items,
  });
}