// *****************************************************************************
// File        : report_data.dart
// Project     : Sri Guru Enterprises
// Description : Container for all data used by the Report module.
//
// This model keeps all enterprise datasets together so the Report screen,
// Excel exporter, PDF exporter and billing-analysis workflow can work from
// the same filtered data.
// *****************************************************************************

class ReportData {
  // ===========================================================================
  // EXISTING MODULE DATA
  // ===========================================================================

  /// Customer records.
  final List<Map<String, dynamic>> customers;

  /// Fleet Service records.
  final List<Map<String, dynamic>> fleetServices;

  /// Emission Test records.
  final List<Map<String, dynamic>> emissionTests;

  /// Car Document records.
  final List<Map<String, dynamic>> carDocuments;

  /// Accessories records.
  final List<Map<String, dynamic>> accessories;

  // ===========================================================================
  // TYRE STOCK
  // ===========================================================================

  /// Tyre Stock records.
  final List<Map<String, dynamic>> tyreStocks;

  // ===========================================================================
  // TYRE BILLING
  // ===========================================================================

  /// Tyre Billing invoice records.
  final List<Map<String, dynamic>> tyreBills;

  // ===========================================================================
  // ALIGNMENT BILLING
  // ===========================================================================

  /// Alignment Billing records.
  final List<Map<String, dynamic>> alignmentBills;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  const ReportData({
    required this.customers,
    required this.fleetServices,
    required this.emissionTests,
    required this.carDocuments,
    required this.accessories,
    required this.tyreStocks,
    required this.tyreBills,
    required this.alignmentBills,
  });

  // ===========================================================================
  // TOTAL RECORDS
  // ===========================================================================

  /// Returns the total number of records across all report sections.
  int get totalRecords {
    return customers.length +
        fleetServices.length +
        emissionTests.length +
        carDocuments.length +
        accessories.length +
        tyreStocks.length +
        tyreBills.length +
        alignmentBills.length;
  }

  // ===========================================================================
  // EMPTY CHECK
  // ===========================================================================

  /// Returns true when every report section contains no records.
  bool get isEmpty {
    return customers.isEmpty &&
        fleetServices.isEmpty &&
        emissionTests.isEmpty &&
        carDocuments.isEmpty &&
        accessories.isEmpty &&
        tyreStocks.isEmpty &&
        tyreBills.isEmpty &&
        alignmentBills.isEmpty;
  }

  // ===========================================================================
  // COPY WITH
  // ===========================================================================

  /// Creates a copy while allowing individual datasets to be replaced.
  ReportData copyWith({
    List<Map<String, dynamic>>? customers,
    List<Map<String, dynamic>>? fleetServices,
    List<Map<String, dynamic>>? emissionTests,
    List<Map<String, dynamic>>? carDocuments,
    List<Map<String, dynamic>>? accessories,
    List<Map<String, dynamic>>? tyreStocks,
    List<Map<String, dynamic>>? tyreBills,
    List<Map<String, dynamic>>? alignmentBills,
  }) {
    return ReportData(
      customers: customers ?? this.customers,
      fleetServices: fleetServices ?? this.fleetServices,
      emissionTests: emissionTests ?? this.emissionTests,
      carDocuments: carDocuments ?? this.carDocuments,
      accessories: accessories ?? this.accessories,
      tyreStocks: tyreStocks ?? this.tyreStocks,
      tyreBills: tyreBills ?? this.tyreBills,
      alignmentBills: alignmentBills ?? this.alignmentBills,
    );
  }
}