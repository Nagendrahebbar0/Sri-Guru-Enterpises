// ============================================================
// FILE: gst_setting.dart
//
// PURPOSE:
// Represents the GST Settings stored in SQLite.
//
// FUNCTIONALITY:
// - Stores the current total GST rate.
// - Stores the last updated timestamp.
//
// IMPORTANT:
// - The application uses ONE total GST rate.
// - SGST and CGST are calculated automatically.
//
// Example:
//
// Total GST = 18%
//
// SGST = 9%
// CGST = 9%
//
// The model does not store SGST and CGST separately because
// they are always calculated as half of the total GST rate.
// ============================================================

class GstSetting {
  // ----------------------------------------------------------
  // DATABASE ID
  // ----------------------------------------------------------

  final int? id;

  // ----------------------------------------------------------
  // TOTAL GST RATE
  //
  // Example:
  //
  // 18.0 = 18%
  // 12.0 = 12%
  // ----------------------------------------------------------

  final double totalGstRate;

  // ----------------------------------------------------------
  // LAST UPDATED
  // ----------------------------------------------------------

  final DateTime updatedAt;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  const GstSetting({
    this.id,
    required this.totalGstRate,
    required this.updatedAt,
  });

  // ==========================================================
  // AUTOMATIC SGST RATE
  //
  // Total GST is divided equally between SGST and CGST.
  // ==========================================================

  double get sgstRate {
    return totalGstRate / 2;
  }

  // ==========================================================
  // AUTOMATIC CGST RATE
  // ==========================================================

  double get cgstRate {
    return totalGstRate / 2;
  }

  // ==========================================================
  // TO MAP
  //
  // Converts the model into a SQLite-compatible map.
  // ==========================================================

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'total_gst_rate': totalGstRate,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // ==========================================================
  // FROM MAP
  //
  // Creates a GstSetting object from a SQLite row.
  // ==========================================================

  factory GstSetting.fromMap(
      Map<String, dynamic> map,
      ) {
    return GstSetting(
      id: _toNullableInt(
        map['id'],
      ),
      totalGstRate: _toDouble(
        map['total_gst_rate'],
      ),
      updatedAt: _toDateTime(
        map['updated_at'],
      ),
    );
  }

  // ==========================================================
  // COPY WITH
  // ==========================================================

  GstSetting copyWith({
    int? id,
    double? totalGstRate,
    DateTime? updatedAt,
  }) {
    return GstSetting(
      id: id ?? this.id,
      totalGstRate:
      totalGstRate ?? this.totalGstRate,
      updatedAt:
      updatedAt ?? this.updatedAt,
    );
  }

  // ==========================================================
  // INTEGER CONVERSION
  // ==========================================================

  static int? _toNullableInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // ==========================================================
  // DOUBLE CONVERSION
  // ==========================================================

  static double _toDouble(
      dynamic value,
      ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    ) ??
        0.0;
  }

  // ==========================================================
  // DATE TIME CONVERSION
  // ==========================================================

  static DateTime _toDateTime(
      dynamic value,
      ) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value?.toString() ?? '',
    ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}