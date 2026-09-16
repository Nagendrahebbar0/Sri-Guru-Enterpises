/// Model representing one tyre item inside a Tyre Bill.
///
/// A single invoice can contain multiple TyreBillItem records.
/// Each item keeps a snapshot of the tyre information used when
/// the invoice was created.
class TyreBillItem {
  final int? id;

  // ID of the parent Tyre Bill.
  final int? billId;

  // ID of the existing Tyre Stock record.
  final int tyreStockId;

  // Tyre information copied from the stock record.
  final String franchise;
  final String vehicleType;
  final String tyre;
  final String pattern;
  final String size;

  // Quantity and selling rate for this invoice item.
  final double quantity;
  final double rate;

  // quantity × rate.
  final double amount;

  const TyreBillItem({
    this.id,
    this.billId,
    required this.tyreStockId,
    required this.franchise,
    required this.vehicleType,
    required this.tyre,
    required this.pattern,
    required this.size,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  /// Fixed HSN code for every tyre billing item.
  ///
  /// This is intentionally not user-editable.
  static const String hsnCode = '40111010';

  /// Calculates the amount from quantity and rate.
  static double calculateAmount(
      double quantity,
      double rate,
      ) {
    return quantity * rate;
  }

  /// Converts the model into a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      'tyre_stock_id': tyreStockId,
      'franchise': franchise,
      'vehicle_type': vehicleType,
      'tyre': tyre,
      'pattern': pattern,
      'size': size,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }

  /// Creates a TyreBillItem object from a SQLite map.
  factory TyreBillItem.fromMap(Map<String, dynamic> map) {
    return TyreBillItem(
      id: _toNullableInt(map['id']),
      billId: _toNullableInt(map['bill_id']),
      tyreStockId: _toInt(map['tyre_stock_id']),
      franchise: map['franchise'] as String? ?? '',
      vehicleType: map['vehicle_type'] as String? ?? '',
      tyre: map['tyre'] as String? ?? '',
      pattern: map['pattern'] as String? ?? '',
      size: map['size'] as String? ?? '',
      quantity: _toDouble(map['quantity']),
      rate: _toDouble(map['rate']),
      amount: _toDouble(map['amount']),
    );
  }

  /// Creates a copy of this item with selected values changed.
  TyreBillItem copyWith({
    int? id,
    int? billId,
    int? tyreStockId,
    String? franchise,
    String? vehicleType,
    String? tyre,
    String? pattern,
    String? size,
    double? quantity,
    double? rate,
    double? amount,
  }) {
    return TyreBillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      tyreStockId: tyreStockId ?? this.tyreStockId,
      franchise: franchise ?? this.franchise,
      vehicleType: vehicleType ?? this.vehicleType,
      tyre: tyre ?? this.tyre,
      pattern: pattern ?? this.pattern,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }
}

/// Converts a database value into an integer.
int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString()) ?? 0;
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