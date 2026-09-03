import 'dart:io';


import 'package:excel_plus/excel_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/report_data.dart';
import 'report_date_filter_service.dart';

/// Creates professional Excel reports for Sri Guru Enterprises.
///
/// Workbook sheets:
/// 1. Customers
/// 2. Fleet Services
/// 3. Emission Tests
/// 4. Car Documents
/// 5. Accessories
class ExcelExportService {
  ExcelExportService._();

  static final ExcelExportService instance = ExcelExportService._();

  // ---------------------------------------------------------------------------
  // PUBLIC METHODS
  // ---------------------------------------------------------------------------

  /// Creates the Excel workbook and returns the generated file.
  Future<File> exportReport({
    required ReportData reportData,
    required ReportDateRange dateRange,
  }) async {
    final Excel excel = Excel.createExcel();

    // Remove the default sheet created by the package.
    final String defaultSheetName =
        excel.getDefaultSheet() ?? 'Sheet1';

    if (excel.sheets.containsKey(defaultSheetName)) {
      excel.delete(defaultSheetName);
    }

    // Create the five required sheets.
    final Sheet customersSheet = excel['Customers'];
    final Sheet fleetSheet = excel['Fleet Services'];
    final Sheet emissionSheet = excel['Emission Tests'];
    final Sheet documentsSheet = excel['Car Documents'];
    final Sheet accessoriesSheet = excel['Accessories'];

    // Write each module.
    _writeCustomers(
      customersSheet,
      reportData.customers,
    );

    _writeFleetServices(
      fleetSheet,
      reportData.fleetServices,
    );

    _writeEmissionTests(
      emissionSheet,
      reportData.emissionTests,
    );

    _writeCarDocuments(
      documentsSheet,
      reportData.carDocuments,
    );

    _writeAccessories(
      accessoriesSheet,
      reportData.accessories,
    );

    // Generate XLSX bytes.
    final List<int>? bytes = excel.save();

    if (bytes == null || bytes.isEmpty) {
      throw Exception('Unable to generate Excel report.');
    }

    final Directory directory = await getTemporaryDirectory();

    final String fileName =
        'Sri_Guru_Enterprises_Report_'
        '${_formatDateForFileName(dateRange.from)}_'
        '${_formatDateForFileName(dateRange.to)}.xlsx';

    final File file = File(
      '${directory.path}/$fileName',
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    return file;
  }

  /// Generates and shares the Excel report using the system share sheet.
  ///
  /// WhatsApp can be selected from the Android share sheet.
  Future<ShareResult> shareReport({
    required ReportData reportData,
    required ReportDateRange dateRange,
  }) async {
    final File file = await exportReport(
      reportData: reportData,
      dateRange: dateRange,
    );

    return SharePlus.instance.share(
      ShareParams(
        title: 'Sri Guru Enterprises Report',
        text: 'Sri Guru Enterprises Report',
        files: <XFile>[
          XFile(file.path),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMERS
  // ---------------------------------------------------------------------------

  void _writeCustomers(
      Sheet sheet,
      List<Map<String, dynamic>> records,
      ) {
    const List<String> headers = <String>[
      'ID',
      'Customer Name',
      'Phone Number',
      'Alternate Phone',
      'Address',
      'Remarks',
    ];

    _writeHeader(sheet, headers);

    for (int i = 0; i < records.length; i++) {
      final Map<String, dynamic> record = records[i];
      final int row = i + 1;

      _setInt(sheet, row, 0, record['id']);
      _setText(sheet, row, 1, record['name']);
      _setText(sheet, row, 2, record['phone']);
      _setText(sheet, row, 3, record['alternate_phone']);
      _setText(sheet, row, 4, record['address']);
      _setText(sheet, row, 5, record['remarks']);

      _formatDataRow(
        sheet,
        row,
        headers.length,
      );
    }

    _setColumnWidths(
      sheet,
      <double>[
        10,
        25,
        18,
        20,
        40,
        30,
      ],
    );

    _finishSheet(
      sheet,
      headers.length,
      records.length,
    );
  }

  // ---------------------------------------------------------------------------
  // FLEET SERVICES
  // ---------------------------------------------------------------------------

  void _writeFleetServices(
      Sheet sheet,
      List<Map<String, dynamic>> records,
      ) {
    const List<String> headers = <String>[
      'ID',
      'Date',
      'Vehicle Brand',
      'Vehicle Type',
      'Vehicle Number',
      'Customer Number',
      'Odometer',
      'Work Done',
      'Total Count',
    ];

    _writeHeader(sheet, headers);

    for (int i = 0; i < records.length; i++) {
      final Map<String, dynamic> record = records[i];
      final int row = i + 1;

      _setInt(sheet, row, 0, record['id']);
      _setText(sheet, row, 1, _formatDate(record['date']));
      _setText(sheet, row, 2, record['vehicle_brand']);
      _setText(sheet, row, 3, record['vehicle_type']);
      _setText(sheet, row, 4, record['vehicle_number']);
      _setText(sheet, row, 5, record['customer_number']);
      _setDouble(sheet, row, 6, record['odometer']);
      _setText(sheet, row, 7, record['work_done']);
      _setDouble(sheet, row, 8, record['total_count']);

      _formatDataRow(
        sheet,
        row,
        headers.length,
      );
    }

    _setColumnWidths(
      sheet,
      <double>[
        10,
        16,
        18,
        22,
        20,
        20,
        15,
        35,
        15,
      ],
    );

    _finishSheet(
      sheet,
      headers.length,
      records.length,
    );
  }

  // ---------------------------------------------------------------------------
  // EMISSION TESTS
  // ---------------------------------------------------------------------------

  void _writeEmissionTests(
      Sheet sheet,
      List<Map<String, dynamic>> records,
      ) {
    const List<String> headers = <String>[
      'ID',
      'Date',
      'Customer Name',
      'Vehicle Number',
      'Income',
      'BBTDU ID No',
      'Fuel Type',
      'Payment Method',
    ];

    _writeHeader(sheet, headers);

    for (int i = 0; i < records.length; i++) {
      final Map<String, dynamic> record = records[i];
      final int row = i + 1;

      _setInt(sheet, row, 0, record['id']);
      _setText(sheet, row, 1, _formatDate(record['date']));
      _setText(sheet, row, 2, record['name']);
      _setText(sheet, row, 3, record['vehicle_number']);
      _setDouble(sheet, row, 4, record['income']);
      _setText(sheet, row, 5, record['bbtdu_id_no']);
      _setText(sheet, row, 6, record['fuel_type']);
      _setText(sheet, row, 7, record['payment_method']);

      _formatDataRow(
        sheet,
        row,
        headers.length,
      );
    }

    _setColumnWidths(
      sheet,
      <double>[
        10,
        16,
        25,
        20,
        15,
        20,
        18,
        18,
      ],
    );

    _finishSheet(
      sheet,
      headers.length,
      records.length,
    );
  }

  // ---------------------------------------------------------------------------
  // CAR DOCUMENTS
  // ---------------------------------------------------------------------------

  void _writeCarDocuments(
      Sheet sheet,
      List<Map<String, dynamic>> records,
      ) {
    const List<String> headers = <String>[
      'ID',
      'Document Type',
      'Other State Name',
      'Date',
      'Expiry Date',
      'Customer Number',
      'Customer Name',
      'Vehicle Number',
      'Income',
      'BBTDU ID No',
      'Expense',
      'Profit',
      'Payment Method',
    ];

    _writeHeader(sheet, headers);

    for (int i = 0; i < records.length; i++) {
      final Map<String, dynamic> record = records[i];
      final int row = i + 1;

      _setInt(sheet, row, 0, record['id']);
      _setText(sheet, row, 1, record['document_type']);
      _setText(sheet, row, 2, record['other_state_name']);
      _setText(sheet, row, 3, _formatDate(record['date']));
      _setText(sheet, row, 4, _formatDate(record['expiry_date']));
      _setText(sheet, row, 5, record['customer_number']);
      _setText(sheet, row, 6, record['customer_name']);
      _setText(sheet, row, 7, record['vehicle_number']);
      _setDouble(sheet, row, 8, record['income']);
      _setText(sheet, row, 9, record['bbtdu_id_no']);
      _setDouble(sheet, row, 10, record['expense']);
      _setDouble(sheet, row, 11, record['profit']);
      _setText(sheet, row, 12, record['payment_method']);

      _formatDataRow(
        sheet,
        row,
        headers.length,
      );
    }

    _setColumnWidths(
      sheet,
      <double>[
        10,
        25,
        22,
        16,
        16,
        20,
        25,
        20,
        15,
        20,
        15,
        15,
        18,
      ],
    );

    _finishSheet(
      sheet,
      headers.length,
      records.length,
    );
  }

  // ---------------------------------------------------------------------------
  // ACCESSORIES
  // ---------------------------------------------------------------------------

  void _writeAccessories(
      Sheet sheet,
      List<Map<String, dynamic>> records,
      ) {
    const List<String> headers = <String>[
      'ID',
      'Date',
      'Customer Number',
      'Customer Name',
      'Item',
      'Quantity',
      'Rate',
      'Total Amount',
      'Payment Method',
      'Remarks',
    ];

    _writeHeader(sheet, headers);

    for (int i = 0; i < records.length; i++) {
      final Map<String, dynamic> record = records[i];
      final int row = i + 1;

      _setInt(sheet, row, 0, record['id']);
      _setText(sheet, row, 1, _formatDate(record['date']));
      _setText(sheet, row, 2, record['customer_number']);
      _setText(sheet, row, 3, record['customer_name']);
      _setText(sheet, row, 4, record['item']);
      _setDouble(sheet, row, 5, record['quantity']);
      _setDouble(sheet, row, 6, record['rate']);
      _setDouble(sheet, row, 7, record['total_amount']);
      _setText(sheet, row, 8, record['payment_method']);
      _setText(sheet, row, 9, record['remarks']);

      _formatDataRow(
        sheet,
        row,
        headers.length,
      );
    }

    _setColumnWidths(
      sheet,
      <double>[
        10,
        16,
        20,
        25,
        22,
        15,
        15,
        18,
        18,
        35,
      ],
    );

    _finishSheet(
      sheet,
      headers.length,
      records.length,
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER FORMATTING
  // ---------------------------------------------------------------------------

  void _writeHeader(
      Sheet sheet,
      List<String> headers,
      ) {
    for (int column = 0; column < headers.length; column++) {
      final Data cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: 0,
        ),
      );

      cell.value = TextCellValue(
        headers[column],
      );

      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // DATA ROW FORMATTING
  // ---------------------------------------------------------------------------

  void _formatDataRow(
      Sheet sheet,
      int row,
      int columnCount,
      ) {
    for (int column = 0; column < columnCount; column++) {
      final Data cell = sheet.cell(
        CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: row,
        ),
      );

      cell.cellStyle = CellStyle(
        verticalAlign: VerticalAlign.Center,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SHEET FINALIZATION
  // ---------------------------------------------------------------------------

  void _finishSheet(
      Sheet sheet,
      int columnCount,
      int recordCount,
      ) {
    // Make the header row slightly taller.
    sheet.setRowHeight(
      0,
      24,
    );

    // Give data rows a comfortable height.
    for (int row = 1; row <= recordCount; row++) {
      sheet.setRowHeight(
        row,
        21,
      );
    }

    // Keep the sheet ready for future filter/freeze-pane integration.
    //
    // The excel package currently handles workbook creation and formatting,
    // while advanced Excel filter/freeze-pane support can be added separately
    // without changing the report data structure.
    //
    // This intentionally avoids package-specific post-processing here so
    // the current verified export remains stable.
  }

  // ---------------------------------------------------------------------------
  // CELL HELPERS
  // ---------------------------------------------------------------------------

  void _setText(
      Sheet sheet,
      int row,
      int column,
      dynamic value,
      ) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
    );

    cell.value = TextCellValue(
      value?.toString() ?? '',
    );
  }

  void _setInt(
      Sheet sheet,
      int row,
      int column,
      dynamic value,
      ) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
    );

    cell.value = IntCellValue(
      _toInt(value),
    );
  }

  void _setDouble(
      Sheet sheet,
      int row,
      int column,
      dynamic value,
      ) {
    final Data cell = sheet.cell(
      CellIndex.indexByColumnRow(
        columnIndex: column,
        rowIndex: row,
      ),
    );

    cell.value = DoubleCellValue(
      _toDouble(value),
    );
  }

  // ---------------------------------------------------------------------------
  // COLUMN WIDTHS
  // ---------------------------------------------------------------------------

  void _setColumnWidths(
      Sheet sheet,
      List<double> widths,
      ) {
    for (int column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(
        column,
        widths[column],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // VALUE CONVERSION
  // ---------------------------------------------------------------------------

  int _toInt(dynamic value) {
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

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0.0;
  }

  // ---------------------------------------------------------------------------
  // DATE FORMATTING
  // ---------------------------------------------------------------------------

  String _formatDate(dynamic value) {
    if (value == null) {
      return '';
    }

    final DateTime? date = DateTime.tryParse(
      value.toString(),
    );

    if (date == null) {
      return value.toString();
    }

    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatDateForFileName(
      DateTime date,
      ) {
    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    return '${date.year}_${month}_$day';
  }
}