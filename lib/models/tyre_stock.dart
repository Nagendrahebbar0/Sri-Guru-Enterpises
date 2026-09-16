// ============================================================
// FILE: tyre_stock.dart
//
// PURPOSE:
// Represents one tyre stock record.
//
// FIELDS:
// - Franchise
// - Vehicle Type
// - Tyre
// - Pattern
// - Size
// - Stock
// - Sell Price
// - LLP
//
// EXAMPLE:
//
// Cherry
// 4 Wheeler
// JK
// Ranger
// 185/65 R15
// Stock: 10
// Sell Price: 4200
// LLP: 3500
// ============================================================

class TyreStock {
  // ============================================================
  // PROPERTIES
  // ============================================================

  final int? id;

  final String franchise;

  final String vehicleType;

  final String tyre;

  final String pattern;

  final String size;

  final int stock;

  final double sellPrice;

  final double llp;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const TyreStock({
    this.id,
    required this.franchise,
    required this.vehicleType,
    required this.tyre,
    required this.pattern,
    required this.size,
    required this.stock,
    required this.sellPrice,
    required this.llp,
  });

  // ============================================================
  // COPY WITH
  //
  // PURPOSE:
  // Creates another TyreStock object while changing only
  // the supplied values.
  // ============================================================

  TyreStock copyWith({
    int? id,
    String? franchise,
    String? vehicleType,
    String? tyre,
    String? pattern,
    String? size,
    int? stock,
    double? sellPrice,
    double? llp,
  }) {
    return TyreStock(
      id: id ?? this.id,
      franchise: franchise ?? this.franchise,
      vehicleType: vehicleType ?? this.vehicleType,
      tyre: tyre ?? this.tyre,
      pattern: pattern ?? this.pattern,
      size: size ?? this.size,
      stock: stock ?? this.stock,
      sellPrice: sellPrice ?? this.sellPrice,
      llp: llp ?? this.llp,
    );
  }

  // ============================================================
  // TO DATABASE MAP
  //
  // PURPOSE:
  // Converts the model into a Map that SQLite understands.
  // ============================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'franchise': franchise,
      'vehicle_type': vehicleType,
      'tyre': tyre,
      'pattern': pattern,
      'size': size,
      'stock': stock,
      'sell_price': sellPrice,
      'llp': llp,
    };
  }

  // ============================================================
  // FROM DATABASE MAP
  //
  // PURPOSE:
  // Converts one SQLite row into a TyreStock object.
  // ============================================================

  factory TyreStock.fromMap(
      Map<String, dynamic> map,
      ) {
    return TyreStock(
      id: _toNullableInt(map['id']),
      franchise:
      map['franchise'] as String? ?? '',
      vehicleType:
      map['vehicle_type'] as String? ?? '',
      tyre:
      map['tyre'] as String? ?? '',
      pattern:
      map['pattern'] as String? ?? '',
      size:
      map['size'] as String? ?? '',
      stock:
      _toInt(map['stock']),
      sellPrice:
      _toDouble(map['sell_price']),
      llp:
      _toDouble(map['llp']),
    );
  }

  // ============================================================
  // INTEGER CONVERSION
  // ============================================================

  static int _toInt(
      dynamic value,
      ) {
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

  // ============================================================
  // NULLABLE INTEGER CONVERSION
  // ============================================================

  static int? _toNullableInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // DOUBLE CONVERSION
  // ============================================================

  static double _toDouble(
      dynamic value,
      ) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }
}