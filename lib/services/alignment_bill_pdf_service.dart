// ============================================================
// FILE: alignment_bill_pdf_service.dart
//
// PURPOSE:
// Generates professional PDF bills for Alignment Billing.
//
// IMPORTANT:
// - Alignment Billing does NOT use GST.
// - This service is completely separate from Tyre Billing.
// - The service only reads the saved AlignmentBill.
// ============================================================

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/alignment_bill.dart';

/// PDF service used for Alignment Bills.
class AlignmentBillPdfService {
  AlignmentBillPdfService._();

  /// Singleton instance.
  static final AlignmentBillPdfService instance =
  AlignmentBillPdfService._();

  // ------------------------------------------------------------
  // COMPANY INFORMATION
  // ------------------------------------------------------------

  static const String _companyName = 'SRI GURU ENTERPRISES';

  static const String _fontRegular =
      'assets/fonts/NotoSans-Regular.ttf';

  static const String _fontBold =
      'assets/fonts/NotoSans-Bold.ttf';

  // ------------------------------------------------------------
  // BUILD PDF
  // ------------------------------------------------------------

  /// Builds the PDF and returns its bytes.
  Future<Uint8List> buildPdf({
    required AlignmentBill bill,
  }) async {
    final _PdfFonts fonts = await _loadFonts();

    final pw.Document pdf = _buildDocument(
      bill: bill,
      fonts: fonts,
    );

    final List<int> bytes = await pdf.save();

    return Uint8List.fromList(bytes);
  }

  // ------------------------------------------------------------
  // EXPORT PDF
  // ------------------------------------------------------------

  /// Creates and saves the Alignment Bill PDF.
  Future<File> exportBill({
    required AlignmentBill bill,
  }) async {
    final _PdfFonts fonts = await _loadFonts();

    final pw.Document pdf = _buildDocument(
      bill: bill,
      fonts: fonts,
    );

    final Directory directory =
    await getApplicationDocumentsDirectory();

    final String safeBillNumber =
    bill.billNumber.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );

    final String fileName =
        'Sri_Guru_Alignment_Bill_$safeBillNumber.pdf';

    final File file = File(
      '${directory.path}/$fileName',
    );

    await file.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    return file;
  }

  // ------------------------------------------------------------
  // SHARE PDF
  // ------------------------------------------------------------

  /// Opens the Android share/print sheet.
  Future<void> shareBill({
    required AlignmentBill bill,
  }) async {
    final File file = await exportBill(
      bill: bill,
    );

    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.path.split(
        Platform.pathSeparator,
      ).last,
    );
  }

  // ------------------------------------------------------------
  // LOAD FONTS
  // ------------------------------------------------------------

  Future<_PdfFonts> _loadFonts() async {
    final ByteData regularData =
    await rootBundle.load(_fontRegular);

    final ByteData boldData =
    await rootBundle.load(_fontBold);

    return _PdfFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }

  // ------------------------------------------------------------
  // BUILD DOCUMENT
  // ------------------------------------------------------------

  pw.Document _buildDocument({
    required AlignmentBill bill,
    required _PdfFonts fonts,
  }) {
    final pw.Document pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        margin: const pw.EdgeInsets.fromLTRB(
          24,
          22,
          24,
          24,
        ),

        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.bold,
        ),

        header: (pw.Context context) {
          return _buildHeader(fonts);
        },

        footer: (pw.Context context) {
          return _buildFooter(context, fonts);
        },

        build: (pw.Context context) {
          return <pw.Widget>[
            _buildTitle(bill, fonts),

            pw.SizedBox(height: 12),

            _buildBillInformation(bill, fonts),

            pw.SizedBox(height: 12),

            _buildCustomerInformation(bill, fonts),

            pw.SizedBox(height: 12),

            _buildVehicleInformation(bill, fonts),

            pw.SizedBox(height: 14),

            _buildServiceTable(bill, fonts),

            pw.SizedBox(height: 12),

            _buildTotal(bill, fonts),

            pw.SizedBox(height: 12),

            _buildPaymentInformation(bill, fonts),

            if (bill.remarks.trim().isNotEmpty) ...<pw.Widget>[
              pw.SizedBox(height: 12),
              _buildRemarks(bill, fonts),
            ],

            pw.SizedBox(height: 35),

            _buildSignature(fonts),
          ];
        },
      ),
    );

    return pdf;
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  pw.Widget _buildHeader(_PdfFonts fonts) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        bottom: 7,
      ),

      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey700,
            width: 0.7,
          ),
        ),
      ),

      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,

        children: <pw.Widget>[
          pw.Text(
            _companyName,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
            ),
          ),

          pw.Text(
            'ALIGNMENT BILLING',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TITLE
  // ------------------------------------------------------------

  pw.Widget _buildTitle(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return pw.Container(
      width: double.infinity,

      padding: const pw.EdgeInsets.all(10),

      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey700,
        ),
      ),

      child: pw.Column(
        children: <pw.Widget>[
          pw.Text(
            'ALIGNMENT BILL',
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 18,
            ),
          ),

          pw.SizedBox(height: 4),

          pw.Text(
            'Wheel Alignment Service',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BILL INFORMATION
  // ------------------------------------------------------------

  pw.Widget _buildBillInformation(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return _buildInformationBox(
      title: 'Bill Information',
      fonts: fonts,
      children: <pw.Widget>[
        _infoRow(
          'Bill Number',
          bill.billNumber,
          fonts,
        ),

        _infoRow(
          'Date',
          _formatDate(bill.date),
          fonts,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CUSTOMER INFORMATION
  // ------------------------------------------------------------

  pw.Widget _buildCustomerInformation(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return _buildInformationBox(
      title: 'Customer Information',
      fonts: fonts,
      children: <pw.Widget>[
        _infoRow(
          'Customer Name',
          bill.customerName,
          fonts,
        ),

        _infoRow(
          'Customer Number',
          bill.customerNumber,
          fonts,
        ),

        if ((bill.address ?? '').trim().isNotEmpty)
          _infoRow(
            'Address',
            bill.address!.trim(),
            fonts,
          ),
      ],
    );
  }

  // ------------------------------------------------------------
  // VEHICLE INFORMATION
  // ------------------------------------------------------------

  pw.Widget _buildVehicleInformation(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return _buildInformationBox(
      title: 'Vehicle Information',
      fonts: fonts,
      children: <pw.Widget>[
        _infoRow(
          'Vehicle Number',
          bill.vehicleNumber,
          fonts,
        ),

        _infoRow(
          'Vehicle Model',
          bill.vehicleModel,
          fonts,
        ),

        _infoRow(
          'KMS',
          bill.kms.toString(),
          fonts,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SERVICE TABLE
  // ------------------------------------------------------------

  pw.Widget _buildServiceTable(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey700,
        width: 0.6,
      ),

      columnWidths: <int, pw.TableColumnWidth>{
        0: const pw.FlexColumnWidth(0.7),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.3),
        4: const pw.FlexColumnWidth(1.5),
      },

      children: <pw.TableRow>[
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey200,
          ),

          children: <pw.Widget>[
            _tableCell(
              'No.',
              fonts,
              bold: true,
            ),

            _tableCell(
              'Service',
              fonts,
              bold: true,
            ),

            _tableCell(
              'Qty',
              fonts,
              bold: true,
            ),

            _tableCell(
              'Rate',
              fonts,
              bold: true,
            ),

            _tableCell(
              'Amount',
              fonts,
              bold: true,
            ),
          ],
        ),

        pw.TableRow(
          children: <pw.Widget>[
            _tableCell(
              '1',
              fonts,
            ),

            _tableCell(
              bill.service,
              fonts,
            ),

            _tableCell(
              _number(bill.quantity),
              fonts,
            ),

            _tableCell(
              _money(bill.rate),
              fonts,
            ),

            _tableCell(
              _money(bill.amount),
              fonts,
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TOTAL
  // ------------------------------------------------------------

  pw.Widget _buildTotal(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,

      child: pw.Container(
        width: 240,

        padding: const pw.EdgeInsets.all(10),

        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey700,
          ),
        ),

        child: pw.Row(
          mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,

          children: <pw.Widget>[
            pw.Text(
              'TOTAL AMOUNT',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 11,
              ),
            ),

            pw.Text(
              _money(bill.amount),
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PAYMENT
  // ------------------------------------------------------------

  pw.Widget _buildPaymentInformation(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return _buildInformationBox(
      title: 'Payment Information',
      fonts: fonts,
      children: <pw.Widget>[
        _infoRow(
          'Payment Method',
          bill.paymentMethod,
          fonts,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // REMARKS
  // ------------------------------------------------------------

  pw.Widget _buildRemarks(
      AlignmentBill bill,
      _PdfFonts fonts,
      ) {
    return _buildInformationBox(
      title: 'Remarks',
      fonts: fonts,
      children: <pw.Widget>[
        pw.Text(
          bill.remarks.trim(),
          style: pw.TextStyle(
            font: fonts.regular,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SIGNATURE
  // ------------------------------------------------------------

  pw.Widget _buildSignature(
      _PdfFonts fonts,
      ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,

      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.center,

        children: <pw.Widget>[
          pw.SizedBox(height: 25),

          pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            'Authorized Signature',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FOOTER
  // ------------------------------------------------------------

  pw.Widget _buildFooter(
      pw.Context context,
      _PdfFonts fonts,
      ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(
        top: 6,
      ),

      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey500,
            width: 0.5,
          ),
        ),
      ),

      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,

        children: <pw.Widget>[
          pw.Text(
            _companyName,
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 7,
            ),
          ),

          pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(
              font: fonts.regular,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION BOX
  // ------------------------------------------------------------

  pw.Widget _buildInformationBox({
    required String title,
    required _PdfFonts fonts,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
      width: double.infinity,

      padding: const pw.EdgeInsets.all(9),

      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey500,
          width: 0.6,
        ),
      ),

      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,

        children: <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: 10,
            ),
          ),

          pw.SizedBox(height: 6),

          ...children,
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFORMATION ROW
  // ------------------------------------------------------------

  pw.Widget _infoRow(
      String label,
      String value,
      _PdfFonts fonts,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 3,
      ),

      child: pw.Row(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,

        children: <pw.Widget>[
          pw.SizedBox(
            width: 105,

            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 8.5,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              value.trim().isEmpty
                  ? '-'
                  : value.trim(),
              style: pw.TextStyle(
                font: fonts.regular,
                fontSize: 8.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // TABLE CELL
  // ------------------------------------------------------------

  pw.Widget _tableCell(
      String text,
      _PdfFonts fonts, {
        bool bold = false,
      }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),

      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold
              ? fonts.bold
              : fonts.regular,
          fontSize: 8,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FORMAT MONEY
  // ------------------------------------------------------------

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  // ------------------------------------------------------------
  // FORMAT NUMBER
  // ------------------------------------------------------------

  String _number(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ------------------------------------------------------------
  // FORMAT DATE
  // ------------------------------------------------------------

  String _formatDate(DateTime date) {
    final String day =
    date.day.toString().padLeft(2, '0');

    final String month =
    date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

// ============================================================
// PDF FONT HOLDER
// ============================================================

class _PdfFonts {
  final pw.Font regular;
  final pw.Font bold;

  const _PdfFonts({
    required this.regular,
    required this.bold,
  });
}