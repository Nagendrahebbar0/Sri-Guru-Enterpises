// ============================================================
// FILE: database_tables.dart
//
// PURPOSE:
// Contains all SQLite table definitions used by the
// Sri Guru Enterprises application.
//
// CURRENT TABLES:
// - Customers
// - Fleet Services
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

class DatabaseTables {
  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  //
  // Prevents this class from being instantiated.
  // ------------------------------------------------------------

  DatabaseTables._();

  // ============================================================
  // CUSTOMERS TABLE
  //
  // Stores customer information used by the Customer
  // Management module.
  //
  // "phone" represents the customer's Customer Number.
  // ============================================================

  static const String createCustomersTable = '''
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL,
      alternate_phone TEXT,
      address TEXT,
      remarks TEXT
    )
  ''';

  // ============================================================
  // FLEET SERVICES TABLE
  //
  // Stores Fleet Service records.
  //
  // Supported brands:
  //
  // - Toyota
  // - Maruti Suzuki
  //
  // Vehicle Type is stored as TEXT because it can contain:
  //
  // - A predefined vehicle type
  // - A custom vehicle type entered by the user
  //
  // Toyota:
  // - Etios
  // - Innova
  // - Innova Crysta
  // - Rumion
  // - Custom
  //
  // Maruti Suzuki:
  // - Dzire
  // - Swift
  // - Ertiga
  // - Tours
  // - Custom
  // ============================================================

  static const String createFleetServicesTable = '''
    CREATE TABLE fleet_services (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      date TEXT NOT NULL,

      vehicle_brand TEXT NOT NULL,

      vehicle_type TEXT NOT NULL,

      vehicle_number TEXT NOT NULL,

      customer_number TEXT NOT NULL,

      odometer INTEGER NOT NULL,

      work_done TEXT NOT NULL,

      total_count INTEGER NOT NULL
    )
  ''';
  // ============================================================
// EMISSION TESTS TABLE
//
// Stores emission test records.
//
// BBTDU ID No is optional.
// Vehicle Number is also optional.
// ============================================================

  static const String createEmissionTestsTable = '''
  CREATE TABLE emission_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    name TEXT NOT NULL,
    vehicle_number TEXT,
    income REAL NOT NULL,
    bbtdu_id_no TEXT,
    fuel_type TEXT NOT NULL,
    payment_method TEXT NOT NULL
  )
''';
}