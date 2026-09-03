// ============================================================
// FILE: accessory.dart
//
// PURPOSE:
// Represents one Accessories transaction in Sri Guru
// Enterprises.
//
// TOTAL AMOUNT:
// Total Amount is automatically calculated as:
//
// Quantity × Rate
// ============================================================

class Accessory {
  // ------------------------------------------------------------
  // DATABASE ID
  // ------------------------------------------------------------

  final int? id;

  // ------------------------------------------------------------
  // TRANSACTION DATE
  // ------------------------------------------------------------

  final DateTime date;

  // ------------------------------------------------------------
  // CUSTOMER DETAILS
  // ------------------------------------------------------------

  final String customerName;
  final String customerNumber;

  // ------------------------------------------------------------
  // ACCESSORY ITEM
  // ------------------------------------------------------------

  final String item;

  // ------------------------------------------------------------
  // QUANTITY
  // ------------------------------------------------------------

  final double quantity;

  // ------------------------------------------------------------
  // RATE
  // ------------------------------------------------------------

  final double rate;

  // ------------------------------------------------------------
  // TOTAL AMOUNT
  //
  // Automatically calculated:
  //
  // quantity × rate
  // ------------------------------------------------------------

  final double totalAmount;

  // ------------------------------------------------------------
  // PAYMENT METHOD
  // ------------------------------------------------------------

  final String paymentMethod;

  // ------------------------------------------------------------
  // OPTIONAL REMARKS
  // ------------------------------------------------------------

  final String remarks;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const Accessory({
    this.id,
    required this.date,
    required this.customerName,
    required this.customerNumber,
    required this.item,
    required this.quantity,
    required this.rate,
    required this.totalAmount,
    required this.paymentMethod,
    required this.remarks,
  });

  // ============================================================
  // CALCULATE TOTAL
  //
  // Keeps the calculation in one place so the UI and database
  // always use the same formula.
  // ============================================================

  static double calculateTotal({
    required double quantity,
    required double rate,
  }) {
    return quantity * rate;
  }

  // ============================================================
  // CONVERT OBJECT TO DATABASE MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date.toIso8601String(),
      'customer_name': customerName,
      'customer_number': customerNumber,
      'item': item,
      'quantity': quantity,
      'rate': rate,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'remarks': remarks,
    };
  }

  // ============================================================
  // CREATE OBJECT FROM DATABASE MAP
  // ============================================================

  factory Accessory.fromMap(
      Map<String, dynamic> map,
      ) {
    return Accessory(
      id: map['id'] as int?,
      date: DateTime.parse(
        map['date'] as String,
      ),
      customerName:
      map['customer_name'] as String? ?? '',
      customerNumber:
      map['customer_number'] as String? ?? '',
      item:
      map['item'] as String? ?? '',
      quantity:
      (map['quantity'] as num?)?.toDouble() ?? 0,
      rate:
      (map['rate'] as num?)?.toDouble() ?? 0,
      totalAmount:
      (map['total_amount'] as num?)?.toDouble() ?? 0,
      paymentMethod:
      map['payment_method'] as String? ?? '',
      remarks:
      map['remarks'] as String? ?? '',
    );
  }

  // ============================================================
  // COPY WITH
  //
  // Useful when creating an edited or duplicated record.
  // ============================================================

  Accessory copyWith({
    int? id,
    DateTime? date,
    String? customerName,
    String? customerNumber,
    String? item,
    double? quantity,
    double? rate,
    double? totalAmount,
    String? paymentMethod,
    String? remarks,
  }) {
    return Accessory(
      id: id ?? this.id,
      date: date ?? this.date,
      customerName:
      customerName ?? this.customerName,
      customerNumber:
      customerNumber ?? this.customerNumber,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      totalAmount:
      totalAmount ?? this.totalAmount,
      paymentMethod:
      paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
    );
  }
}