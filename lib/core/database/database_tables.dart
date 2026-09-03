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
// - Emission Tests
// - Car Documents
// - Accessories
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

class DatabaseTables {
  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  // ------------------------------------------------------------

  DatabaseTables._();

  // ============================================================
  // CUSTOMERS TABLE
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

  // ============================================================
  // CAR DOCUMENTS TABLE
  //
  // Stores Insurance, Road Tax and Permit documents.
  //
  // Other State Name is only used when:
  //
  // document_type = Other State Permit
  //
  // Profit is calculated automatically:
  //
  // Profit = Income - Expense
  // ============================================================

  static const String createCarDocumentsTable = '''
    CREATE TABLE car_documents (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      document_type TEXT NOT NULL,

      other_state_name TEXT,

      date TEXT NOT NULL,

      expiry_date TEXT NOT NULL,

      customer_number TEXT NOT NULL,

      customer_name TEXT NOT NULL,

      vehicle_number TEXT NOT NULL,

      income REAL NOT NULL,

      bbtdu_id_no TEXT,

      expense REAL NOT NULL,

      profit REAL NOT NULL,

      payment_method TEXT NOT NULL
    )
  ''';

  // ============================================================
  // ACCESSORIES TABLE
  //
  // Stores all Accessories records.
  //
  // The Item field is restricted by the Accessories screen to:
  // - Trip Sheet
  // - Bill Book
  // - Water Bottle
  // - Tissue Paper
  // - Car Perfume
  // - Print Out
  // - Xerox
  //
  // Total Amount is calculated automatically:
  // Total Amount = Quantity × Rate
  // ============================================================

  static const String createAccessoriesTable = '''
    CREATE TABLE accessories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      date TEXT NOT NULL,

      customer_name TEXT NOT NULL,

      customer_number TEXT NOT NULL,

      item TEXT NOT NULL,

      quantity REAL NOT NULL,

      rate REAL NOT NULL,

      total_amount REAL NOT NULL,

      payment_method TEXT NOT NULL,

      remarks TEXT NOT NULL
    )
  ''';

}