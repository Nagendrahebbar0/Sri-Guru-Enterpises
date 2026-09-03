// *****************************************************************************
// File        : report_data.dart
// Project     : Sri Guru Enterprises
// Description : Container for all data used by the Report module.
//
// This model keeps the five enterprise datasets together so the Report screen,
// Excel exporter and PDF exporter can all work from the same filtered data.
// *****************************************************************************

class ReportData {
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> fleetServices;
  final List<Map<String, dynamic>> emissionTests;
  final List<Map<String, dynamic>> carDocuments;
  final List<Map<String, dynamic>> accessories;

  const ReportData({
    required this.customers,
    required this.fleetServices,
    required this.emissionTests,
    required this.carDocuments,
    required this.accessories,
  });

  /// Total number of records across all report sections.
  int get totalRecords {
    return customers.length +
        fleetServices.length +
        emissionTests.length +
        carDocuments.length +
        accessories.length;
  }

  /// Returns true when every report section has no records.
  bool get isEmpty {
    return customers.isEmpty &&
        fleetServices.isEmpty &&
        emissionTests.isEmpty &&
        carDocuments.isEmpty &&
        accessories.isEmpty;
  }

  /// Returns a copy with optionally replaced datasets.
  ReportData copyWith({
    List<Map<String, dynamic>>? customers,
    List<Map<String, dynamic>>? fleetServices,
    List<Map<String, dynamic>>? emissionTests,
    List<Map<String, dynamic>>? carDocuments,
    List<Map<String, dynamic>>? accessories,
  }) {
    return ReportData(
      customers: customers ?? this.customers,
      fleetServices: fleetServices ?? this.fleetServices,
      emissionTests: emissionTests ?? this.emissionTests,
      carDocuments: carDocuments ?? this.carDocuments,
      accessories: accessories ?? this.accessories,
    );
  }
}