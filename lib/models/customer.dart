// ============================================================
// FILE: customer.dart
//
// PURPOSE:
// Defines the Customer model used by Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Represents one customer.
// - Stores customer information.
// - Converts customer data into a database-compatible Map.
// - Creates a Customer object from database data.
// ============================================================

// ============================================================
// CUSTOMER MODEL
//
// This class represents one customer in the application.
//
// Example:
//
// Customer(
//   name: 'Santhosh Kumar',
//   phone: '9902551811',
//   address: 'Bangalore',
// )
//
// IMPORTANT:
// "phone" represents the Customer Number because we have
// decided that the customer's contact number is their
// Customer Number.
// ============================================================

class Customer {
  // ------------------------------------------------------------
  // DATABASE ID
  //
  // This is an internal SQLite ID.
  //
  // It is NOT the Customer Number shown to the user.
  //
  // SQLite can automatically generate this value.
  // ------------------------------------------------------------

  final int? id;

  // ------------------------------------------------------------
  // CUSTOMER NAME
  //
  // Stores the customer's name.
  // ------------------------------------------------------------

  final String name;

  // ------------------------------------------------------------
  // CUSTOMER NUMBER
  //
  // This is the customer's contact/mobile number.
  //
  // Example:
  //
  // 9902551811
  //
  // We will store it as String instead of int because phone
  // numbers are identifiers, not mathematical values.
  // ------------------------------------------------------------

  final String phone;

  // ------------------------------------------------------------
  // ALTERNATE NUMBER
  //
  // Optional secondary contact number.
  // ------------------------------------------------------------

  final String? alternatePhone;

  // ------------------------------------------------------------
  // ADDRESS
  //
  // Stores the customer's address.
  // ------------------------------------------------------------

  final String? address;

  // ------------------------------------------------------------
  // REMARKS
  //
  // Optional additional information about the customer.
  // ------------------------------------------------------------

  final String? remarks;

  // ============================================================
  // CONSTRUCTOR
  //
  // Creates a Customer object.
  // ============================================================

  const Customer({
    this.id,
    required this.name,
    required this.phone,
    this.alternatePhone,
    this.address,
    this.remarks,
  });

  // ============================================================
  // TO MAP
  //
  // Converts the Customer object into a Map.
  //
  // SQLite works with key/value data, so we need to convert
  // our Dart object into a Map before inserting it into the
  // database.
  //
  // Example:
  //
  // Customer object
  //       ↓
  // toMap()
  //       ↓
  // {
  //   'id': 1,
  //   'name': 'Santhosh Kumar',
  //   'phone': '9902551811',
  //   ...
  // }
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      // --------------------------------------------------------
      // INTERNAL DATABASE ID
      // --------------------------------------------------------

      'id': id,

      // --------------------------------------------------------
      // CUSTOMER NAME
      // --------------------------------------------------------

      'name': name,

      // --------------------------------------------------------
      // CUSTOMER NUMBER / CONTACT NUMBER
      // --------------------------------------------------------

      'phone': phone,

      // --------------------------------------------------------
      // ALTERNATE CONTACT NUMBER
      // --------------------------------------------------------

      'alternate_phone': alternatePhone,

      // --------------------------------------------------------
      // CUSTOMER ADDRESS
      // --------------------------------------------------------

      'address': address,

      // --------------------------------------------------------
      // CUSTOMER REMARKS
      // --------------------------------------------------------

      'remarks': remarks,
    };
  }

  // ============================================================
  // FROM MAP
  //
  // Creates a Customer object from database data.
  //
  // SQLite returns records as Maps.
  //
  // Example:
  //
  // Database
  //    ↓
  // Map<String, dynamic>
  //    ↓
  // Customer.fromMap()
  //    ↓
  // Customer object
  // ============================================================

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      // --------------------------------------------------------
      // DATABASE ID
      // --------------------------------------------------------

      id: map['id'] as int?,

      // --------------------------------------------------------
      // CUSTOMER NAME
      // --------------------------------------------------------

      name: map['name'] as String,

      // --------------------------------------------------------
      // CUSTOMER NUMBER / CONTACT NUMBER
      // --------------------------------------------------------

      phone: map['phone'] as String,

      // --------------------------------------------------------
      // ALTERNATE CONTACT NUMBER
      // --------------------------------------------------------

      alternatePhone: map['alternate_phone'] as String?,

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      address: map['address'] as String?,

      // --------------------------------------------------------
      // REMARKS
      // --------------------------------------------------------

      remarks: map['remarks'] as String?,
    );
  }

  // ============================================================
  // COPY WITH
  //
  // Creates a new Customer object while allowing selected
  // values to be changed.
  //
  // This is useful when editing an existing customer.
  //
  // Example:
  //
  // existingCustomer.copyWith(
  //   name: 'New Name',
  // );
  //
  // The other information remains unchanged.
  // ============================================================

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? alternatePhone,
    String? address,
    String? remarks,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
    );
  }
}