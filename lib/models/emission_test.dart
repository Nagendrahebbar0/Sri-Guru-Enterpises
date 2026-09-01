// ============================================================
// FILE: emission_test.dart
//
// PURPOSE:
// Defines the Emission Test data model used by Sri Guru
// Enterprises.
//
// FUNCTIONALITY:
// - Represents one emission test record.
// - Stores service date.
// - Stores customer name.
// - Stores vehicle number.
// - Stores income.
// - Stores optional BBTDU ID number.
// - Stores fuel type.
// - Stores payment method.
//
// IMPORTANT:
// BBTDU ID No is OPTIONAL.
// Vehicle No is also OPTIONAL based on the requested fields.
// ============================================================

class EmissionTest {
  // ============================================================
  // DATABASE ID
  //
  // Internal SQLite ID.
  // ============================================================

  final int? id;

  // ============================================================
  // DATE
  //
  // Date on which the emission test was performed.
  // ============================================================

  final DateTime date;

  // ============================================================
  // NAME
  //
  // Customer/person name.
  // ============================================================

  final String name;

  // ============================================================
  // VEHICLE NUMBER
  //
  // Vehicle registration number.
  //
  // This is optional.
  // ============================================================

  final String? vehicleNumber;

  // ============================================================
  // INCOME
  //
  // Amount received for the emission test.
  // ============================================================

  final double income;

  // ============================================================
  // BBTDU ID NUMBER
  //
  // Optional BBTDU identification number.
  //
  // This field may be empty/null.
  // ============================================================

  final String? bbtdUIdNo;

  // ============================================================
  // FUEL TYPE
  //
  // Supported values:
  //
  // - Petrol
  // - Diesel
  // ============================================================

  final String fuelType;

  // ============================================================
  // PAYMENT METHOD
  //
  // Examples:
  //
  // - Cash
  // - G Pay
  // - Duty
  //
  // The field is stored as text so entries such as
  // "G Pay/781" can also be preserved.
  // ============================================================

  final String paymentMethod;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const EmissionTest({
    this.id,
    required this.date,
    required this.name,
    this.vehicleNumber,
    required this.income,
    this.bbtdUIdNo,
    required this.fuelType,
    required this.paymentMethod,
  });

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
      // DATE
      // --------------------------------------------------------

      'date': date.toIso8601String(),

      // --------------------------------------------------------
      // NAME
      // --------------------------------------------------------

      'name': name,

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
      //
      // This can be null because the field is optional.
      // --------------------------------------------------------

      'bbtdu_id_no': bbtdUIdNo,

      // --------------------------------------------------------
      // FUEL TYPE
      // --------------------------------------------------------

      'fuel_type': fuelType,

      // --------------------------------------------------------
      // PAYMENT METHOD
      // --------------------------------------------------------

      'payment_method': paymentMethod,
    };
  }

  // ============================================================
  // FROM MAP
  //
  // Creates an EmissionTest object from a SQLite row.
  // ============================================================

  factory EmissionTest.fromMap(
      Map<String, dynamic> map,
      ) {
    return EmissionTest(
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      id: map['id'] as int?,

      // --------------------------------------------------------
      // DATE
      // --------------------------------------------------------

      date: DateTime.parse(
        map['date'] as String,
      ),

      // --------------------------------------------------------
      // NAME
      // --------------------------------------------------------

      name: map['name'] as String,

      // --------------------------------------------------------
      // VEHICLE NUMBER
      //
      // May be null.
      // --------------------------------------------------------

      vehicleNumber:
      map['vehicle_number'] as String?,

      // --------------------------------------------------------
      // INCOME
      //
      // SQLite may return an integer or double.
      // Convert safely to double.
      // --------------------------------------------------------

      income:
      (map['income'] as num).toDouble(),

      // --------------------------------------------------------
      // BBTDU ID NUMBER
      //
      // Optional.
      // --------------------------------------------------------

      bbtdUIdNo:
      map['bbtdu_id_no'] as String?,

      // --------------------------------------------------------
      // FUEL TYPE
      // --------------------------------------------------------

      fuelType:
      map['fuel_type'] as String,

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
  // Creates a modified copy of an existing emission record.
  // ============================================================

  EmissionTest copyWith({
    int? id,
    DateTime? date,
    String? name,
    String? vehicleNumber,
    double? income,
    String? bbtdUIdNo,
    String? fuelType,
    String? paymentMethod,
  }) {
    return EmissionTest(
      // --------------------------------------------------------
      // PRESERVE EXISTING VALUES
      // --------------------------------------------------------

      id: id ?? this.id,

      date: date ?? this.date,

      name: name ?? this.name,

      vehicleNumber:
      vehicleNumber ?? this.vehicleNumber,

      income:
      income ?? this.income,

      bbtdUIdNo:
      bbtdUIdNo ?? this.bbtdUIdNo,

      fuelType:
      fuelType ?? this.fuelType,

      paymentMethod:
      paymentMethod ?? this.paymentMethod,
    );
  }
}