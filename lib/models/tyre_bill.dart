/// Model representing the main information of a Tyre Bill.
///
/// One TyreBill can contain multiple TyreBillItem records.
/// The invoice stores the GST rate and calculated tax amounts
/// used at the time the invoice was created so old invoices
/// remain unchanged when the GST setting is changed later.
class TyreBill {
  final int? id;

  // Invoice number such as INV125, INV126, INV127, etc.
  final String invoiceNumber;

  // GST Invoice or Non-GST Invoice.
  final String billType;

  // GST Invoice Number is required only for GST invoices.
  final String? gstInvoiceNumber;

  // Invoice date.
  final DateTime date;

  // Existing Customer table ID.
  final int? customerId;

  // Customer details stored as an invoice snapshot.
  final String customerName;
  final String customerNumber;
  final String? address;

  // GST-related customer information.
  final String? gstin;
  final String? legalName;
  final String? tradeName;

  // Vehicle number for which the tyres are being billed.
  final String vehicleNumber;

  /// Vehicle odometer reading in kilometres.
  final int kms;

  // Amount before GST.
  final double taxableAmount;

  // GST rates used for this particular invoice.
  final double sgstRate;
  final double sgstAmount;

  final double cgstRate;
  final double cgstAmount;

  // Final invoice amount including GST.
  final double grandTotal;

  // Payment method such as Cash or G Pay.
  final String paymentMethod;

  // Optional invoice remarks.
  final String remarks;

  // Record timestamps.
  final DateTime createdAt;
  final DateTime updatedAt;

  const TyreBill({
    this.id,
    required this.invoiceNumber,
    required this.billType,
    this.gstInvoiceNumber,
    required this.date,
    this.customerId,
    required this.customerName,
    required this.customerNumber,
    this.address,
    this.gstin,
    this.legalName,
    this.tradeName,
    required this.vehicleNumber,
    required this.kms,
    required this.taxableAmount,
    required this.sgstRate,
    required this.sgstAmount,
    required this.cgstRate,
    required this.cgstAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Fixed HSN code for all tyre billing items.
  ///
  /// The user does not enter or edit this value.
  static const String hsnCode = '40111010';

  /// Returns the total GST rate used by this invoice.
  double get totalGstRate => sgstRate + cgstRate;

  /// Converts the model into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'invoice_number': invoiceNumber,
      'bill_type': billType,
      'gst_invoice_number': gstInvoiceNumber,
      'date': date.toIso8601String(),
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_number': customerNumber,
      'address': address,
      'gstin': gstin,
      'legal_name': legalName,
      'trade_name': tradeName,
      'vehicle_number': vehicleNumber,
      'kms': kms,
      'taxable_amount': taxableAmount,
      'sgst_rate': sgstRate,
      'sgst_amount': sgstAmount,
      'cgst_rate': cgstRate,
      'cgst_amount': cgstAmount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a TyreBill object from a SQLite map.
  factory TyreBill.fromMap(Map<String, dynamic> map) {
    return TyreBill(
      id: _toNullableInt(map['id']),
      invoiceNumber: map['invoice_number'] as String? ?? '',
      billType: map['bill_type'] as String? ?? '',
      gstInvoiceNumber:
      map['gst_invoice_number'] as String?,
      date: _toDateTime(map['date']),
      customerId: _toNullableInt(map['customer_id']),
      customerName: map['customer_name'] as String? ?? '',
      customerNumber:
      map['customer_number'] as String? ?? '',
      address: map['address'] as String?,
      gstin: map['gstin'] as String?,
      legalName: map['legal_name'] as String?,
      tradeName: map['trade_name'] as String?,
      vehicleNumber:
      map['vehicle_number'] as String? ?? '',
      kms: (map['kms'] as num?)?.toInt() ?? 0,
      taxableAmount: _toDouble(map['taxable_amount']),
      sgstRate: _toDouble(map['sgst_rate']),
      sgstAmount: _toDouble(map['sgst_amount']),
      cgstRate: _toDouble(map['cgst_rate']),
      cgstAmount: _toDouble(map['cgst_amount']),
      grandTotal: _toDouble(map['grand_total']),
      paymentMethod:
      map['payment_method'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  /// Creates a copy of this bill with selected values changed.
  TyreBill copyWith({
    int? id,
    String? invoiceNumber,
    String? billType,
    String? gstInvoiceNumber,
    DateTime? date,
    int? customerId,
    String? customerName,
    String? customerNumber,
    String? address,
    String? gstin,
    String? legalName,
    String? tradeName,
    String? vehicleNumber,
    int? kms,
    double? taxableAmount,
    double? sgstRate,
    double? sgstAmount,
    double? cgstRate,
    double? cgstAmount,
    double? grandTotal,
    String? paymentMethod,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TyreBill(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      billType: billType ?? this.billType,
      gstInvoiceNumber:
      gstInvoiceNumber ?? this.gstInvoiceNumber,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerNumber:
      customerNumber ?? this.customerNumber,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      legalName: legalName ?? this.legalName,
      tradeName: tradeName ?? this.tradeName,
      vehicleNumber:
      vehicleNumber ?? this.vehicleNumber,
      kms: kms ?? this.kms,
      taxableAmount:
      taxableAmount ?? this.taxableAmount,
      sgstRate: sgstRate ?? this.sgstRate,
      sgstAmount: sgstAmount ?? this.sgstAmount,
      cgstRate: cgstRate ?? this.cgstRate,
      cgstAmount: cgstAmount ?? this.cgstAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod:
      paymentMethod ?? this.paymentMethod,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Converts a database value into a nullable integer.
int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

/// Converts a database value into a double.
double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString()) ?? 0;
}

/// Converts a database date value into DateTime.
DateTime _toDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }

  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}