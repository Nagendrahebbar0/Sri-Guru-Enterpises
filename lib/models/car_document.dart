// ============================================================
// FILE: car_document.dart
//
// PURPOSE:
// Defines the Car Document data model used by Sri Guru
// Enterprises.
//
// SUPPORTED DOCUMENT TYPES:
// - Insurance
// - Road Tax
// - Kerala Permit
// - Tamil Nadu Permit
// - Andhra Pradesh Permit
// - Other State Permit
//
// IMPORTANT:
// - Expiry Date is required.
// - Other State Name is only required for Other State Permit.
// - BBTDU ID No is optional.
// - Profit is calculated automatically.
//
// PROFIT FORMULA:
//
// Profit = Income - Expense
// ============================================================

class CarDocument {
  // ============================================================
  // DATABASE ID
  // ============================================================

  final int? id;

  // ============================================================
  // DOCUMENT TYPE
  // ============================================================

  final String documentType;

  // ============================================================
  // OTHER STATE NAME
  //
  // Used only when documentType is:
  //
  // Other State Permit
  //
  // Example:
  //
  // Karnataka
  // ============================================================

  final String? otherStateName;

  // ============================================================
  // DATE
  //
  // Date on which the document/service was recorded.
  // ============================================================

  final DateTime date;

  // ============================================================
  // EXPIRY DATE
  //
  // Required.
  //
  // This will also be used later for expiry reminders.
  // ============================================================

  final DateTime expiryDate;

  // ============================================================
  // CUSTOMER NUMBER
  //
  // Customer's contact/mobile number.
  // ============================================================

  final String customerNumber;

  // ============================================================
  // CUSTOMER NAME
  // ============================================================

  final String customerName;

  // ============================================================
  // VEHICLE NUMBER
  // ============================================================

  final String vehicleNumber;

  // ============================================================
  // INCOME
  // ============================================================

  final double income;

  // ============================================================
  // BBTDU ID NUMBER
  //
  // Optional.
  // ============================================================

  final String? bbtdUIdNo;

  // ============================================================
  // EXPENSE
  // ============================================================

  final double expense;

  // ============================================================
  // PROFIT
  //
  // Automatically calculated:
  //
  // Income - Expense
  // ============================================================

  final double profit;

  // ============================================================
  // PAYMENT METHOD
  //
  // Examples:
  //
  // - Cash
  // - G Pay
  // ============================================================

  final String paymentMethod;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const CarDocument({
    this.id,
    required this.documentType,
    this.otherStateName,
    required this.date,
    required this.expiryDate,
    required this.customerNumber,
    required this.customerName,
    required this.vehicleNumber,
    required this.income,
    this.bbtdUIdNo,
    required this.expense,
    required this.profit,
    required this.paymentMethod,
  });

  // ============================================================
  // CALCULATE PROFIT
  //
  // Centralized helper so the same formula can be used
  // throughout the application.
  // ============================================================

  static double calculateProfit({
    required double income,
    required double expense,
  }) {
    return income - expense;
  }

  // ============================================================
  // TO MAP
  //
  // Converts the model into a SQLite-compatible Map.
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      'id': id,

      // --------------------------------------------------------
      // DOCUMENT TYPE
      // --------------------------------------------------------

      'document_type': documentType,

      // --------------------------------------------------------
      // OTHER STATE NAME
      // --------------------------------------------------------

      'other_state_name': otherStateName,

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      'date': date.toIso8601String(),

      // --------------------------------------------------------
      // EXPIRY DATE
      // --------------------------------------------------------

      'expiry_date': expiryDate.toIso8601String(),

      // --------------------------------------------------------
      // CUSTOMER NUMBER
      // --------------------------------------------------------

      'customer_number': customerNumber,

      // --------------------------------------------------------
      // CUSTOMER NAME
      // --------------------------------------------------------

      'customer_name': customerName,

      // --------------------------------------------------------
      // VEHICLE NUMBER
      // --------------------------------------------------------

      'vehicle_number': vehicleNumber,

      // --------------------------------------------------------
      // INCOME
      // --------------------------------------------------------

      'income': income,

      // --------------------------------------------------------
      // BBTDU ID NUMBER
      // --------------------------------------------------------

      'bbtdu_id_no': bbtdUIdNo,

      // --------------------------------------------------------
      // EXPENSE
      // --------------------------------------------------------

      'expense': expense,

      // --------------------------------------------------------
      // PROFIT
      // --------------------------------------------------------

      'profit': profit,

      // --------------------------------------------------------
      // PAYMENT METHOD
      // --------------------------------------------------------

      'payment_method': paymentMethod,
    };
  }

  // ============================================================
  // FROM MAP
  //
  // Creates a CarDocument object from a SQLite row.
  // ============================================================

  factory CarDocument.fromMap(
      Map<String, dynamic> map,
      ) {
    return CarDocument(
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      id: map['id'] as int?,

      // --------------------------------------------------------
      // DOCUMENT TYPE
      // --------------------------------------------------------

      documentType:
      map['document_type'] as String,

      // --------------------------------------------------------
      // OTHER STATE NAME
      // --------------------------------------------------------

      otherStateName:
      map['other_state_name'] as String?,

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      date: DateTime.parse(
        map['date'] as String,
      ),

      // --------------------------------------------------------
      // EXPIRY DATE
      // --------------------------------------------------------

      expiryDate: DateTime.parse(
        map['expiry_date'] as String,
      ),

      // --------------------------------------------------------
      // CUSTOMER NUMBER
      // --------------------------------------------------------

      customerNumber:
      map['customer_number'] as String,

      // --------------------------------------------------------
      // CUSTOMER NAME
      // --------------------------------------------------------

      customerName:
      map['customer_name'] as String,

      // --------------------------------------------------------
      // VEHICLE NUMBER
      // --------------------------------------------------------

      vehicleNumber:
      map['vehicle_number'] as String,

      // --------------------------------------------------------
      // INCOME
      //
      // SQLite can return int or double.
      // --------------------------------------------------------

      income:
      (map['income'] as num).toDouble(),

      // --------------------------------------------------------
      // BBTDU ID NUMBER
      // --------------------------------------------------------

      bbtdUIdNo:
      map['bbtdu_id_no'] as String?,

      // --------------------------------------------------------
      // EXPENSE
      // --------------------------------------------------------

      expense:
      (map['expense'] as num).toDouble(),

      // --------------------------------------------------------
      // PROFIT
      // --------------------------------------------------------

      profit:
      (map['profit'] as num).toDouble(),

      // --------------------------------------------------------
      // PAYMENT METHOD
      // --------------------------------------------------------

      paymentMethod:
      map['payment_method'] as String,
    );
  }

  // ============================================================
  // COPY WITH
  //
  // Creates a modified copy of an existing Car Document.
  // ============================================================

  CarDocument copyWith({
    int? id,
    String? documentType,
    String? otherStateName,
    DateTime? date,
    DateTime? expiryDate,
    String? customerNumber,
    String? customerName,
    String? vehicleNumber,
    double? income,
    String? bbtdUIdNo,
    double? expense,
    double? profit,
    String? paymentMethod,
  }) {
    return CarDocument(
      id: id ?? this.id,
      documentType: documentType ?? this.documentType,
      otherStateName:
      otherStateName ?? this.otherStateName,
      date: date ?? this.date,
      expiryDate:
      expiryDate ?? this.expiryDate,
      customerNumber:
      customerNumber ?? this.customerNumber,
      customerName:
      customerName ?? this.customerName,
      vehicleNumber:
      vehicleNumber ?? this.vehicleNumber,
      income: income ?? this.income,
      bbtdUIdNo:
      bbtdUIdNo ?? this.bbtdUIdNo,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      paymentMethod:
      paymentMethod ?? this.paymentMethod,
    );
  }
}