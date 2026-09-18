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

  // ============================================================
  // TYRE STOCK TABLE
  //
  // PURPOSE:
  // Stores tyre stock available at Sri Guru Enterprises.
  //
  // STOCK IS SEPARATED BY:
  // - Franchise
  // - Vehicle Type
  // - Tyre
  // - Pattern
  // - Size
  //
  // FRANCHISES:
  // - Cherry
  // - Tyreplex
  //
  // VEHICLE TYPES:
  // - 2 Wheeler
  // - 4 Wheeler
  //
  // FIELDS:
  // - id
  // - franchise
  // - vehicle_type
  // - tyre
  // - pattern
  // - size
  // - stock
  // - sell_price
  // - llp
  //
  // UNIQUE RULE:
  // A duplicate is not allowed for the same:
  // Franchise + Vehicle Type + Tyre + Pattern + Size
  //
  // This separation is important because the same tyre may be
  // available from both Cherry and Tyreplex.
  // ============================================================

  static const String createTyreStocksTable = '''
  CREATE TABLE tyre_stocks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    franchise TEXT NOT NULL,
    vehicle_type TEXT NOT NULL,
    tyre TEXT NOT NULL,
    pattern TEXT NOT NULL,
    size TEXT NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    sell_price REAL NOT NULL DEFAULT 0,
    llp REAL NOT NULL DEFAULT 0,
    UNIQUE(
      franchise,
      vehicle_type,
      tyre,
      pattern,
      size
    )
  )
''';

  // ============================================================
  // GST SETTINGS TABLE
  //
  // Stores the current/default total GST rate used by the
  // Tyre Billing module.
  //
  // The application stores ONE total GST rate.
  //
  // Example:
  // Total GST = 18%
  // SGST = 9%
  // CGST = 9%
  //
  // SGST and CGST are calculated automatically by the billing
  // module. They are NOT stored as separately editable settings.
  // ============================================================

  static const String createGstSettingsTable = '''
  CREATE TABLE gst_settings (
    id INTEGER PRIMARY KEY,
    total_gst_rate REAL NOT NULL,
    updated_at TEXT NOT NULL
  )
''';
  // ============================================================
  // TYRE BILLS TABLE
  //
  // Stores the main invoice information for Tyre Billing.
  //
  // Customer details are stored as a snapshot so that an old
  // invoice remains unchanged even if the customer information
  // is edited later.
  // ============================================================

  static const String createTyreBillsTable = '''
    CREATE TABLE tyre_bills (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      invoice_number TEXT NOT NULL UNIQUE,

      bill_type TEXT NOT NULL,

      gst_invoice_number TEXT,

      date TEXT NOT NULL,

      customer_id INTEGER,

      customer_name TEXT NOT NULL,

      customer_number TEXT NOT NULL,

      address TEXT,

      gstin TEXT,

      legal_name TEXT,

      trade_name TEXT,

      vehicle_number TEXT NOT NULL,

      vehicle_model TEXT NOT NULL DEFAULT 'Others',
      
      kms INTEGER NOT NULL DEFAULT 0,

      taxable_amount REAL NOT NULL DEFAULT 0,

      sgst_rate REAL NOT NULL DEFAULT 0,

      sgst_amount REAL NOT NULL DEFAULT 0,

      cgst_rate REAL NOT NULL DEFAULT 0,

      cgst_amount REAL NOT NULL DEFAULT 0,

      grand_total REAL NOT NULL DEFAULT 0,

      payment_method TEXT NOT NULL,

      remarks TEXT NOT NULL DEFAULT '',

      created_at TEXT NOT NULL,

      updated_at TEXT NOT NULL
    )
  ''';

  // ============================================================
  // TYRE BILL ITEMS TABLE
  //
  // Stores individual tyre items belonging to a Tyre Bill.
  //
  // One Tyre Bill can contain multiple tyre items.
  //
  // The tyre stock ID connects the bill item to the existing
  // Tyre Stock record. The descriptive tyre information is also
  // stored here so the invoice remains historically accurate
  // even if the stock record is changed later.
  // ============================================================

  static const String createTyreBillItemsTable = '''
    CREATE TABLE tyre_bill_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,

      bill_id INTEGER NOT NULL,

      tyre_stock_id INTEGER NOT NULL,

      franchise TEXT NOT NULL,

      vehicle_type TEXT NOT NULL,

      tyre TEXT NOT NULL,

      pattern TEXT NOT NULL,

      size TEXT NOT NULL,

      quantity REAL NOT NULL,

      rate REAL NOT NULL,

      amount REAL NOT NULL,

      FOREIGN KEY (bill_id)
        REFERENCES tyre_bills(id)
        ON DELETE CASCADE
    )
  ''';
}
