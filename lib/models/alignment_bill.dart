// ============================================================
// FILE: alignment_bill.dart
//
// PURPOSE:
// Represents one Simple Alignment Bill in the application.
//
// This model matches the SQLite `alignment_bills` table.
//
// IMPORTANT:
// - Alignment Bills do NOT use GST.
// - GSTIN, CGST, SGST and tax fields are intentionally absent.
// - The model stores the final amount directly.
// ============================================================

class AlignmentBill {
  // ------------------------------------------------------------
  // DATABASE ID
  // ------------------------------------------------------------

  final int? id;

  // ------------------------------------------------------------
  // BILL INFORMATION
  // ------------------------------------------------------------

  /// Unique Alignment Bill number.
  final String billNumber;

  /// Date on which the Alignment Bill was created.
  final DateTime date;

  // ------------------------------------------------------------
  // CUSTOMER INFORMATION
  // ------------------------------------------------------------

  /// ID of the selected customer, when available.
  final int? customerId;

  /// Customer name copied into the bill.
  final String customerName;

  /// Customer contact/mobile number copied into the bill.
  final String customerNumber;

  /// Customer address copied into the bill.
  final String? address;

  // ------------------------------------------------------------
  // VEHICLE INFORMATION
  // ------------------------------------------------------------

  /// Vehicle registration number.
  final String vehicleNumber;

  /// Vehicle model selected for the alignment bill.
  /// When Others is selected, the custom model name is stored here.
  final String vehicleModel;

  /// Vehicle odometer reading in kilometres.
  final int kms;

  // ------------------------------------------------------------
  // ALIGNMENT SERVICE
  // ------------------------------------------------------------

  /// Service performed.
  ///
  /// For the current Simple Alignment Bill this will normally be:
  /// `Wheel Alignment`
  final String service;

  /// Number of alignment services.
  final double quantity;

  /// Rate charged for one service.
  final double rate;

  /// Total amount.
  ///
  /// Normally:
  /// quantity × rate
  final double amount;

  // ------------------------------------------------------------
  // PAYMENT INFORMATION
  // ------------------------------------------------------------

  /// Payment method.
  ///
  /// Supported values:
  /// - Cash
  /// - G Pay
  final String paymentMethod;

  // ------------------------------------------------------------
  // REMARKS
  // ------------------------------------------------------------

  /// Optional remarks associated with the bill.
  final String remarks;

  // ------------------------------------------------------------
  // TIMESTAMPS
  // ------------------------------------------------------------

  /// Record creation timestamp.
  final DateTime createdAt;

  /// Record last-update timestamp.
  final DateTime updatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const AlignmentBill({
    this.id,
    required this.billNumber,
    required this.date,
    this.customerId,
    required this.customerName,
    required this.customerNumber,
    this.address,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.kms,
    required this.service,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.paymentMethod,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // Converts the Dart object into a Map that can be inserted
  // or updated in SQLite.
  // ============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'bill_number': billNumber,
      'date': date.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_number': customerNumber,
      'address': address,
      'vehicle_number': vehicleNumber,
      'vehicle_model': vehicleModel,
      'kms': kms,
      'service': service,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
      'payment_method': paymentMethod,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Converts a SQLite row into an AlignmentBill object.
  // ============================================================

  factory AlignmentBill.fromMap(
      Map<String, dynamic> map,
      ) {
    return AlignmentBill(
      id: map['id'] as int?,
      billNumber: map['bill_number'] as String,
      date: DateTime.parse(
        map['date'] as String,
      ),
      customerId: map['customer_id'] as int?,
      customerName: map['customer_name'] as String,
      customerNumber: map['customer_number'] as String,
      address: map['address'] as String?,
      vehicleNumber: map['vehicle_number'] as String,
      vehicleModel: map['vehicle_model'] as String? ?? 'Others',
      kms: (map['kms'] as num?)?.toInt() ?? 0,
      service: map['service'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentMethod: map['payment_method'] as String,
      remarks: map['remarks'] as String? ?? '',
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================
  //
  // Creates a new AlignmentBill while allowing selected values
  // to be changed.
  //
  // This is useful for editing and duplicating bills.
  // ============================================================

  AlignmentBill copyWith({
    int? id,
    String? billNumber,
    DateTime? date,
    int? customerId,
    String? customerName,
    String? customerNumber,
    String? address,
    String? vehicleNumber,
    String? vehicleModel,
    int? kms,
    String? service,
    double? quantity,
    double? rate,
    double? amount,
    String? paymentMethod,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlignmentBill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerNumber: customerNumber ?? this.customerNumber,
      address: address ?? this.address,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      kms: kms ?? this.kms,
      service: service ?? this.service,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}