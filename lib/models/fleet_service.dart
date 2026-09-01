// ============================================================
// FILE: fleet_service.dart
//
// PURPOSE:
// Defines the Fleet Service data model used by the Sri Guru
// Enterprises application.
//
// FUNCTIONALITY:
// - Represents one Fleet Service record.
// - Stores service date.
// - Stores vehicle brand.
// - Stores vehicle type.
// - Stores vehicle registration number.
// - Stores customer's contact number.
// - Stores vehicle odometer reading.
// - Stores work performed.
// - Stores the running total count.
//
// SUPPORTED VEHICLE BRANDS:
//
// Toyota:
// - Etios
// - Innova
// - Innova Crysta
// - Rumion
// - Custom Vehicle Type
//
// Maruti Suzuki:
// - Dzire
// - Swift
// - Ertiga
// - Tours
// - Custom Vehicle Type
//
// IMPORTANT:
// "Customer Number" means the customer's contact/mobile number.
// ============================================================

class FleetService {
  // ============================================================
  // DATABASE ID
  //
  // SQLite automatically generates this value.
  // ============================================================

  final int? id;

  // ============================================================
  // SERVICE DATE
  //
  // Date on which the fleet service was performed.
  // ============================================================

  final DateTime date;

  // ============================================================
  // VEHICLE BRAND
  //
  // Currently supported:
  //
  // - Toyota
  // - Maruti Suzuki
  // ============================================================

  final String vehicleBrand;

  // ============================================================
  // VEHICLE TYPE
  //
  // Examples:
  //
  // Toyota:
  // - Etios
  // - Innova
  // - Innova Crysta
  // - Rumion
  //
  // Maruti Suzuki:
  // - Dzire
  // - Swift
  // - Ertiga
  // - Tours
  //
  // A custom vehicle type can also be stored here.
  // ============================================================

  final String vehicleType;

  // ============================================================
  // VEHICLE NUMBER
  //
  // Example:
  //
  // KA03AP3691
  // ============================================================

  final String vehicleNumber;

  // ============================================================
  // CUSTOMER NUMBER
  //
  // This is the customer's contact/mobile number.
  //
  // It corresponds to the "phone" field in our Customer
  // Management module.
  // ============================================================

  final String customerNumber;

  // ============================================================
  // ODOMETER
  //
  // Current vehicle odometer reading in kilometres.
  //
  // Example:
  //
  // 125430
  // ============================================================

  final int odometer;

  // ============================================================
  // WORK DONE
  //
  // Example:
  //
  // Oil Change
  // ============================================================

  final String workDone;

  // ============================================================
  // TOTAL COUNT
  //
  // Running Fleet Service count.
  //
  // Example:
  //
  // 1
  // 2
  // 3
  // ...
  // ============================================================

  final int totalCount;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const FleetService({
    this.id,
    required this.date,
    required this.vehicleBrand,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.customerNumber,
    required this.odometer,
    required this.workDone,
    required this.totalCount,
  });

  // ============================================================
  // TO MAP
  //
  // Converts the FleetService object into a Map.
  //
  // This format will be used when inserting or updating the
  // record in SQLite.
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      'id': id,

      // --------------------------------------------------------
      // SERVICE DATE
      //
      // SQLite stores this as text.
      // --------------------------------------------------------

      'date': date.toIso8601String(),

      // --------------------------------------------------------
      // VEHICLE BRAND
      // --------------------------------------------------------

      'vehicle_brand': vehicleBrand,

      // --------------------------------------------------------
      // VEHICLE TYPE
      // --------------------------------------------------------

      'vehicle_type': vehicleType,

      // --------------------------------------------------------
      // VEHICLE NUMBER
      // --------------------------------------------------------

      'vehicle_number': vehicleNumber,

      // --------------------------------------------------------
      // CUSTOMER NUMBER
      // --------------------------------------------------------

      'customer_number': customerNumber,

      // --------------------------------------------------------
      // ODOMETER
      // --------------------------------------------------------

      'odometer': odometer,

      // --------------------------------------------------------
      // WORK DONE
      // --------------------------------------------------------

      'work_done': workDone,

      // --------------------------------------------------------
      // TOTAL COUNT
      // --------------------------------------------------------

      'total_count': totalCount,
    };
  }

  // ============================================================
  // FROM MAP
  //
  // Creates a FleetService object from a SQLite database row.
  // ============================================================

  factory FleetService.fromMap(
      Map<String, dynamic> map,
      ) {
    return FleetService(
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      id: map['id'] as int?,

      // --------------------------------------------------------
      // SERVICE DATE
      // --------------------------------------------------------

      date: DateTime.parse(
        map['date'] as String,
      ),

      // --------------------------------------------------------
      // VEHICLE BRAND
      // --------------------------------------------------------

      vehicleBrand:
      map['vehicle_brand'] as String,

      // --------------------------------------------------------
      // VEHICLE TYPE
      // --------------------------------------------------------

      vehicleType:
      map['vehicle_type'] as String,

      // --------------------------------------------------------
      // VEHICLE NUMBER
      // --------------------------------------------------------

      vehicleNumber:
      map['vehicle_number'] as String,

      // --------------------------------------------------------
      // CUSTOMER NUMBER
      // --------------------------------------------------------

      customerNumber:
      map['customer_number'] as String,

      // --------------------------------------------------------
      // ODOMETER
      // --------------------------------------------------------

      odometer:
      map['odometer'] as int,

      // --------------------------------------------------------
      // WORK DONE
      // --------------------------------------------------------

      workDone:
      map['work_done'] as String,

      // --------------------------------------------------------
      // TOTAL COUNT
      // --------------------------------------------------------

      totalCount:
      map['total_count'] as int,
    );
  }

  // ============================================================
  // COPY WITH
  //
  // Creates a copy of the Fleet Service while allowing
  // individual values to be changed.
  //
  // This will be useful when editing a Fleet Service record.
  // ============================================================

  FleetService copyWith({
    int? id,
    DateTime? date,
    String? vehicleBrand,
    String? vehicleType,
    String? vehicleNumber,
    String? customerNumber,
    int? odometer,
    String? workDone,
    int? totalCount,
  }) {
    return FleetService(
      // --------------------------------------------------------
      // PRESERVE EXISTING VALUES WHEN NO NEW VALUE IS PROVIDED
      // --------------------------------------------------------

      id: id ?? this.id,

      date: date ?? this.date,

      vehicleBrand:
      vehicleBrand ?? this.vehicleBrand,

      vehicleType:
      vehicleType ?? this.vehicleType,

      vehicleNumber:
      vehicleNumber ?? this.vehicleNumber,

      customerNumber:
      customerNumber ?? this.customerNumber,

      odometer:
      odometer ?? this.odometer,

      workDone:
      workDone ?? this.workDone,

      totalCount:
      totalCount ?? this.totalCount,
    );
  }
}