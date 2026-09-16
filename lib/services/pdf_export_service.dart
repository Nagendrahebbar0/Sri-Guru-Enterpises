// ****************************************************************************
// FILE        : pdf_export_service.dart
// PROJECT     : Sri Guru Enterprises
// DESCRIPTION : PDF export service for the Report module.
//
// Creates a professional multi-page PDF using the same filtered ReportData
// and ReportDateRange used by the Report screen and Excel exporter.
//
// REPORT SECTIONS:
// 1. Customers
// 2. Fleet Services
// 3. Emission Tests
// 4. Car Documents
// 5. Accessories
// 6. Tyre Stock
// 7. Tyre Billing
// 8. Alignment Billing
// ****************************************************************************

import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/report_data.dart';
import 'report_date_filter_service.dart';

class PdfExportService {
  // --------------------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  // --------------------------------------------------------------------------

  PdfExportService._();

  // --------------------------------------------------------------------------
  // SINGLETON INSTANCE
  // --------------------------------------------------------------------------

  static final PdfExportService instance =
  PdfExportService._();

  // --------------------------------------------------------------------------
  // DATE FORMAT
  // --------------------------------------------------------------------------

  final DateFormat _dateFormat =
  DateFormat('dd/MM/yyyy');

  // ==========================================================================
  // EXPORT PDF
  // ==========================================================================

  Future<File> exportReport({
    required ReportData reportData,
    required ReportDateRange dateRange,
  }) async {
    final pw.Document pdf =
    pw.Document();

    // ------------------------------------------------------------------------
    // CREATE MULTI-PAGE PDF
    // ------------------------------------------------------------------------

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),

        // --------------------------------------------------------------
        // PAGE HEADER
        // --------------------------------------------------------------

        header: (pw.Context context) {
          return _buildHeader();
        },

        // --------------------------------------------------------------
        // PAGE FOOTER
        // --------------------------------------------------------------

        footer: (pw.Context context) {
          return _buildFooter(context);
        },

        // --------------------------------------------------------------
        // PDF CONTENT
        // --------------------------------------------------------------

        build: (pw.Context context) {
          return <pw.Widget>[
            // Report title.
            _buildReportTitle(dateRange),

            pw.SizedBox(height: 18),

            // Report summary.
            _buildSummary(reportData),

            // --------------------------------------------------------
            // CUSTOMERS
            // --------------------------------------------------------

            _buildCustomersSection(
              reportData.customers,
            ),

            // --------------------------------------------------------
            // FLEET SERVICES
            // --------------------------------------------------------

            _buildFleetServicesSection(
              reportData.fleetServices,
            ),

            // --------------------------------------------------------
            // EMISSION TESTS
            // --------------------------------------------------------

            _buildEmissionTestsSection(
              reportData.emissionTests,
            ),

            // --------------------------------------------------------
            // CAR DOCUMENTS
            // --------------------------------------------------------

            _buildCarDocumentsSection(
              reportData.carDocuments,
            ),

            // --------------------------------------------------------
            // ACCESSORIES
            // --------------------------------------------------------

            _buildAccessoriesSection(
              reportData.accessories,
            ),

            // --------------------------------------------------------
            // TYRE STOCK
            // --------------------------------------------------------

            _buildTyreStockSection(
              reportData.tyreStocks,
            ),

            // --------------------------------------------------------
            // TYRE BILLING
            // --------------------------------------------------------

            _buildTyreBillingSection(
              reportData.tyreBills,
            ),

            // --------------------------------------------------------
            // ALIGNMENT BILLING
            // --------------------------------------------------------

            _buildAlignmentBillingSection(
              reportData.alignmentBills,
            ),
          ];
        },
      ),
    );

    // =========================================================================
    // SAVE PDF
    // =========================================================================

    final Directory directory =
    await getApplicationDocumentsDirectory();

    final String from =
    DateFormat('yyyy_MM_dd')
        .format(dateRange.from);

    final String to =
    DateFormat('yyyy_MM_dd')
        .format(dateRange.to);

    final String fileName =
        'Sri_Guru_Enterprises_Report_${from}_$to.pdf';

    final File file = File(
      '${directory.path}/$fileName',
    );

    await file.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    return file;
  }

  // ==========================================================================
  // SHARE PDF
  // ==========================================================================

  Future<void> shareReport({
    required ReportData reportData,
    required ReportDateRange dateRange,
  }) async {
    final File file =
    await exportReport(
      reportData: reportData,
      dateRange: dateRange,
    );

    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename:
      file.path.split(
        Platform.pathSeparator,
      ).last,
    );
  }

  // ==========================================================================
  // HEADER
  // ==========================================================================

  pw.Widget _buildHeader() {
    return pw.Container(
      padding:
      const pw.EdgeInsets.only(
        bottom: 8,
      ),
      decoration:
      const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Text(
        'Sri Guru Enterprises',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ==========================================================================
  // FOOTER
  // ==========================================================================

  pw.Widget _buildFooter(
      pw.Context context,
      ) {
    return pw.Container(
      padding:
      const pw.EdgeInsets.only(
        top: 8,
      ),
      decoration:
      const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'Sri Guru Enterprises',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // REPORT TITLE
  // ==========================================================================

  pw.Widget _buildReportTitle(
      ReportDateRange dateRange,
      ) {
    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Enterprise Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight:
            pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Report Period: '
              '${_dateFormat.format(dateRange.from)}'
              ' - '
              '${_dateFormat.format(dateRange.to)}',
          style: const pw.TextStyle(
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // SUMMARY
  // ==========================================================================

  pw.Widget _buildSummary(
      ReportData data,
      ) {
    return pw.Container(
      padding:
      const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey,
        ),
        borderRadius:
        pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'Report Summary',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border:
            pw.TableBorder.all(
              color: PdfColors.grey,
            ),
            children: <pw.TableRow>[
              _summaryRow(
                'Customers',
                data.customers.length,
              ),
              _summaryRow(
                'Fleet Services',
                data.fleetServices.length,
              ),
              _summaryRow(
                'Emission Tests',
                data.emissionTests.length,
              ),
              _summaryRow(
                'Car Documents',
                data.carDocuments.length,
              ),
              _summaryRow(
                'Accessories',
                data.accessories.length,
              ),
              _summaryRow(
                'Tyre Stock',
                data.tyreStocks.length,
              ),
              _summaryRow(
                'Tyre Billing',
                data.tyreBills.length,
              ),
              _summaryRow(
                'Alignment Billing',
                data.alignmentBills.length,
              ),
              _summaryRow(
                'Total Records',
                data.totalRecords,
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.TableRow _summaryRow(
      String title,
      int count,
      ) {
    return pw.TableRow(
      children: <pw.Widget>[
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(6),
          child: pw.Text(title),
        ),
        pw.Padding(
          padding:
          const pw.EdgeInsets.all(6),
          child: pw.Text(
            '$count',
            textAlign:
            pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // CUSTOMERS
  // ==========================================================================

  pw.Widget _buildCustomersSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Customers',
      headers: <String>[
        'ID',
        'Customer Name',
        'Phone Number',
        'Alternate Phone',
        'Address',
        'Remarks',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _value(row['name']),
            _value(row['phone']),
            _value(row['alternate_phone']),
            _value(row['address']),
            _value(row['remarks']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // FLEET SERVICES
  // ==========================================================================

  pw.Widget _buildFleetServicesSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Fleet Services',
      headers: <String>[
        'ID',
        'Date',
        'Vehicle Brand',
        'Vehicle Type',
        'Vehicle Number',
        'Customer Number',
        'Odometer',
        'Work Done',
        'Total Count',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _formatDatabaseDate(
              row['date'],
            ),
            _value(row['vehicle_brand']),
            _value(row['vehicle_type']),
            _value(row['vehicle_number']),
            _value(row['customer_number']),
            _value(row['odometer']),
            _value(row['work_done']),
            _value(row['total_count']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // EMISSION TESTS
  // ==========================================================================

  pw.Widget _buildEmissionTestsSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Emission Tests',
      headers: <String>[
        'ID',
        'Date',
        'Customer Name',
        'Vehicle Number',
        'Income',
        'BBTDU ID No',
        'Fuel Type',
        'Payment Method',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _formatDatabaseDate(
              row['date'],
            ),
            _value(row['name']),
            _value(row['vehicle_number']),
            _value(row['income']),
            _value(row['bbtdu_id_no']),
            _value(row['fuel_type']),
            _value(row['payment_method']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // CAR DOCUMENTS
  // ==========================================================================

  pw.Widget _buildCarDocumentsSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Car Documents',
      headers: <String>[
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
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _value(row['document_type']),
            _value(row['other_state_name']),
            _formatDatabaseDate(
              row['date'],
            ),
            _formatDatabaseDate(
              row['expiry_date'],
            ),
            _value(row['customer_number']),
            _value(row['customer_name']),
            _value(row['vehicle_number']),
            _value(row['income']),
            _value(row['bbtdu_id_no']),
            _value(row['expense']),
            _value(row['profit']),
            _value(row['payment_method']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // ACCESSORIES
  // ==========================================================================

  pw.Widget _buildAccessoriesSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Accessories',
      headers: <String>[
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
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _formatDatabaseDate(
              row['date'],
            ),
            _value(row['customer_number']),
            _value(row['customer_name']),
            _value(row['item']),
            _value(row['quantity']),
            _value(row['rate']),
            _value(row['total_amount']),
            _value(row['payment_method']),
            _value(row['remarks']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // TYRE STOCK
  // ==========================================================================

  pw.Widget _buildTyreStockSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Tyre Stock',
      headers: <String>[
        'ID',
        'Franchise',
        'Vehicle Type',
        'Tyre',
        'Pattern',
        'Size',
        'Stock',
        'Sell Price',
        'LLP',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _value(row['franchise']),
            _value(row['vehicle_type']),
            _value(row['tyre']),
            _value(row['pattern']),
            _value(row['size']),
            _value(row['stock']),
            _value(row['sell_price']),
            _value(row['llp']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // TYRE BILLING
  // ==========================================================================

  pw.Widget _buildTyreBillingSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Tyre Billing',
      headers: <String>[
        'ID',
        'Invoice Number',
        'Bill Type',
        'GST Invoice Number',
        'Date',
        'Customer Name',
        'Customer Number',
        'Vehicle Number',
        'KMS',
        'GSTIN',
        'Legal Name',
        'Trade Name',
        'Taxable Amount',
        'SGST Rate',
        'SGST Amount',
        'CGST Rate',
        'CGST Amount',
        'Grand Total',
        'Payment Method',
        'Remarks',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _value(row['invoice_number']),
            _value(row['bill_type']),
            _value(row['gst_invoice_number']),
            _formatDatabaseDate(
              row['date'],
            ),
            _value(row['customer_name']),
            _value(row['customer_number']),
            _value(row['vehicle_number']),
            _value(row['kms']),
            _value(row['gstin']),
            _value(row['legal_name']),
            _value(row['trade_name']),
            _value(row['taxable_amount']),
            _value(row['sgst_rate']),
            _value(row['sgst_amount']),
            _value(row['cgst_rate']),
            _value(row['cgst_amount']),
            _value(row['grand_total']),
            _value(row['payment_method']),
            _value(row['remarks']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // ALIGNMENT BILLING
  // ==========================================================================

  pw.Widget _buildAlignmentBillingSection(
      List<Map<String, dynamic>> rows,
      ) {
    return _buildSection(
      title: 'Alignment Billing',
      headers: <String>[
        'ID',
        'Bill Number',
        'Date',
        'Customer Name',
        'Customer Number',
        'Address',
        'Vehicle Number',
        'KMS',
        'Service',
        'Quantity',
        'Rate',
        'Amount',
        'Payment Method',
        'Remarks',
      ],
      rows: rows.map(
            (Map<String, dynamic> row) {
          return <String>[
            _value(row['id']),
            _value(row['bill_number']),
            _formatDatabaseDate(
              row['date'],
            ),
            _value(row['customer_name']),
            _value(row['customer_number']),
            _value(row['address']),
            _value(row['vehicle_number']),
            _value(row['kms']),
            _value(row['service']),
            _value(row['quantity']),
            _value(row['rate']),
            _value(row['amount']),
            _value(row['payment_method']),
            _value(row['remarks']),
          ];
        },
      ).toList(),
    );
  }

  // ==========================================================================
  // GENERIC SECTION
  // ==========================================================================

  pw.Widget _buildSection({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Column(
      crossAxisAlignment:
      pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(height: 22),

        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 17,
            fontWeight:
            pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 8),

        // ------------------------------------------------------------
        // Empty section.
        // ------------------------------------------------------------

        if (rows.isEmpty)
          pw.Container(
            width: double.infinity,
            padding:
            const pw.EdgeInsets.all(10),
            decoration:
            pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.grey,
              ),
            ),
            child: pw.Text(
              'No records found for this section.',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey,
              ),
            ),
          )

        // ------------------------------------------------------------
        // Section table.
        // ------------------------------------------------------------

        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,

            headerStyle: pw.TextStyle(
              fontSize: 7,
              fontWeight:
              pw.FontWeight.bold,
            ),

            cellStyle:
            const pw.TextStyle(
              fontSize: 6.5,
            ),

            headerDecoration:
            const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),

            cellPadding:
            const pw.EdgeInsets.all(4),

            border:
            pw.TableBorder.all(
              color: PdfColors.grey,
              width: 0.5,
            ),

            columnWidths:
            _buildColumnWidths(
              headers.length,
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // COLUMN WIDTHS
  // ==========================================================================

  Map<int, pw.TableColumnWidth>
  _buildColumnWidths(
      int columnCount,
      ) {
    final Map<int, pw.TableColumnWidth>
    widths =
    <int, pw.TableColumnWidth>{};

    for (int i = 0;
    i < columnCount;
    i++) {
      widths[i] =
      const pw.FlexColumnWidth();
    }

    return widths;
  }

  // ==========================================================================
  // DATABASE DATE FORMAT
  // ==========================================================================

  String _formatDatabaseDate(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    final String text =
    value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      return _dateFormat.format(
        DateTime.parse(text),
      );
    } catch (_) {
      return text;
    }
  }

  // ==========================================================================
  // GENERIC VALUE
  // ==========================================================================

  String _value(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }
}