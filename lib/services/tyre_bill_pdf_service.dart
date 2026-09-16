// *****************************************************************************
// File        : tyre_bill_pdf_service.dart
// Project     : Sri Guru Enterprises
// Description : Creates, shares and prints professional Tyre Billing invoices.
//
// PDF design follows the professional TAX INVOICE style requested by the user.
// The invoice uses the SAME tax-inclusive values already calculated and stored
// in TyreBill and TyreBillItem.
//
// HSN Code is fixed as 40111010.
// Currency uses the real ₹ symbol through embedded Noto Sans fonts.
// *****************************************************************************

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/tyre_bill.dart';
import '../models/tyre_bill_item.dart';

class TyreBillPdfService {
  TyreBillPdfService._();

  /// Single shared instance of the PDF service.
  static final TyreBillPdfService instance = TyreBillPdfService._();

  // ---------------------------------------------------------------------------
  // CONSTANTS
  // ---------------------------------------------------------------------------

  static const String _regularFontPath =
      'assets/fonts/NotoSans-Regular.ttf';
  static const String _boldFontPath = 'assets/fonts/NotoSans-Bold.ttf';

  static const String _companyName = 'SRI GURU ENTERPRISES';
  static const String _invoiceTitle = 'TAX INVOICE';
  static const String _originalCopy = 'ORIGINAL FOR RECIPIENT';

  /// Fixed HSN code required by the Tyre Billing module.
  static const String _hsnCode = TyreBillItem.hsnCode;

  // ---------------------------------------------------------------------------
  // FORMATS
  // ---------------------------------------------------------------------------


  final DateFormat _longDateFormat = DateFormat('dd MMM yyyy');

  // ---------------------------------------------------------------------------
  // MONEY FORMAT
  // ---------------------------------------------------------------------------

  /// Formats money using the actual Indian Rupee symbol.
  ///
  /// The PDF uses embedded Noto Sans fonts so ₹ is rendered correctly instead
  /// of appearing as a missing-glyph box.
  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  // ---------------------------------------------------------------------------
  // FONT LOADING
  // ---------------------------------------------------------------------------

  /// Loads the regular and bold Noto Sans fonts bundled with the application.
  Future<_PdfFonts> _loadFonts() async {
    final ByteData regularData =
    await rootBundle.load(_regularFontPath);
    final ByteData boldData = await rootBundle.load(_boldFontPath);

    return _PdfFonts(
      regular: pw.Font.ttf(regularData),
      bold: pw.Font.ttf(boldData),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT PDF
  // ---------------------------------------------------------------------------

  /// Creates the invoice PDF and saves it inside the application's documents
  /// directory.
  Future<File> exportBill({
    required TyreBill bill,
    required List<TyreBillItem> items,
  }) async {
    final _PdfFonts fonts = await _loadFonts();
    final pw.Document pdf = _buildDocument(
      bill: bill,
      items: items,
      fonts: fonts,
    );

    final Directory directory = await getApplicationDocumentsDirectory();

    final String safeInvoiceNumber =
    bill.invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

    final String fileName =
        'Sri_Guru_Invoice_$safeInvoiceNumber.pdf';

    final File file = File('${directory.path}/$fileName');

    await file.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    return file;
  }

  // ---------------------------------------------------------------------------
  // BUILD PDF BYTES
  // ---------------------------------------------------------------------------

  /// Builds the invoice PDF and returns it as Uint8List.
  ///
  /// This method is used by the Print button on the Invoice Preview screen.
  /// It uses the same PDF layout as exportBill() and shareBill().
  Future<Uint8List> buildPdf({
    required TyreBill bill,
    required List<TyreBillItem> items,
  }) async {
    final _PdfFonts fonts = await _loadFonts();
    final pw.Document pdf = _buildDocument(
      bill: bill,
      items: items,
      fonts: fonts,
    );

    final List<int> bytes = await pdf.save();
    return Uint8List.fromList(bytes);
  }

  // ---------------------------------------------------------------------------
  // SHARE PDF
  // ---------------------------------------------------------------------------

  /// Generates the invoice PDF and opens the Android sharing/printing sheet.
  Future<void> shareBill({
    required TyreBill bill,
    required List<TyreBillItem> items,
  }) async {
    final File file = await exportBill(
      bill: bill,
      items: items,
    );

    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.path.split(Platform.pathSeparator).last,
    );
  }

  // ---------------------------------------------------------------------------
  // DOCUMENT
  // ---------------------------------------------------------------------------

  /// Builds the complete professional invoice document.
  pw.Document _buildDocument({
    required TyreBill bill,
    required List<TyreBillItem> items,
    required _PdfFonts fonts,
  }) {
    final pw.Document pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 24),
        theme: pw.ThemeData.withFont(
          base: fonts.regular,
          bold: fonts.bold,
        ),
        header: (pw.Context context) {
          return _buildPageHeader();
        },
        footer: (pw.Context context) {
          return _buildFooter(context);
        },
        build: (pw.Context context) {
          return <pw.Widget>[
            _buildInvoiceHeading(),
            pw.SizedBox(height: 8),
            _buildTopInformation(bill),
            pw.SizedBox(height: 8),
            _buildCustomerInformation(bill),
            pw.SizedBox(height: 10),
            _buildItemsTable(bill, items),
            pw.SizedBox(height: 8),
            _buildTotals(bill),
            pw.SizedBox(height: 8),
            _buildAmountInWords(bill),
            pw.SizedBox(height: 8),
            _buildPaymentSection(bill),
            pw.SizedBox(height: 8),
            _buildSignatureSection(),
          ];
        },
      ),
    );

    return pdf;
  }

  // ---------------------------------------------------------------------------
  // PAGE HEADER
  // ---------------------------------------------------------------------------

  pw.Widget _buildPageHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            _companyName,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'TYRE BILLING',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey500,
            width: 0.5,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: <pw.Widget>[
          pw.Text(
            'This is a computer generated document.',
            style: const pw.TextStyle(fontSize: 7),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INVOICE HEADING
  // ---------------------------------------------------------------------------

  pw.Widget _buildInvoiceHeading() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey700,
          width: 0.8,
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                _invoiceTitle,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          pw.Text(
            _originalCopy,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOP INFORMATION
  // ---------------------------------------------------------------------------

  pw.Widget _buildTopInformation(TyreBill bill) {
    final List<List<String>> invoiceRows = <List<String>>[
      <String>['Invoice #', bill.invoiceNumber],
      <String>['Invoice Date', _longDateFormat.format(bill.date)],
      <String>['Invoice Type', bill.billType],
      <String>['Payment', bill.paymentMethod],
    ];

    if (bill.billType == 'GST Invoice' &&
        (bill.gstInvoiceNumber ?? '').trim().isNotEmpty) {
      invoiceRows.add(<String>[
        'GST Invoice Number',
        bill.gstInvoiceNumber!.trim(),
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey500,
        width: 0.6,
      ),
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(2.8),
      },
      children: <pw.TableRow>[
        pw.TableRow(
          children: <pw.Widget>[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Tyre Billing',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: invoiceRows.map(_smallInfoLine).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _smallInfoLine(List<String> row) {
    if (row.length < 2) {
      return pw.SizedBox();
    }

    return _labelValue(row[0], row[1]);
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CUSTOMER INFORMATION
  // ---------------------------------------------------------------------------

  pw.Widget _buildCustomerInformation(TyreBill bill) {
    final List<List<String>> rows = <List<String>>[
      <String>['Customer Name', bill.customerName],
      <String>['Customer Number', bill.customerNumber],
    ];

    if ((bill.address ?? '').trim().isNotEmpty) {
      rows.add(<String>['Billing Address', bill.address!.trim()]);
    }

    if ((bill.legalName ?? '').trim().isNotEmpty) {
      rows.add(<String>['Legal Name', bill.legalName!.trim()]);
    }

    if ((bill.tradeName ?? '').trim().isNotEmpty) {
      rows.add(<String>['Trade Name', bill.tradeName!.trim()]);
    }

    if ((bill.gstin ?? '').trim().isNotEmpty) {
      rows.add(<String>['GSTIN', bill.gstin!.trim()]);
    }

    rows.add(<String>['Vehicle Number', bill.vehicleNumber]);
    rows.add(<String>['KMS', bill.kms.toString()]);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Customer Details'),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey500,
            width: 0.6,
          ),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FlexColumnWidth(1.35),
            1: pw.FlexColumnWidth(3.65),
          },
          children: rows.map((List<String> row) {
            return pw.TableRow(
              children: <pw.Widget>[
                _cell(row[0], bold: true),
                _cell(row[1]),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ITEMS TABLE
  // ---------------------------------------------------------------------------

  pw.Widget _buildItemsTable(
      TyreBill bill,
      List<TyreBillItem> items,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        _sectionTitle('Tyre Details'),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey600,
            width: 0.6,
          ),
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(22),
            1: pw.FlexColumnWidth(2.8),
            2: pw.FixedColumnWidth(48),
            3: pw.FixedColumnWidth(32),
            4: pw.FixedColumnWidth(34),
            5: pw.FixedColumnWidth(58),
            6: pw.FixedColumnWidth(28),
            7: pw.FlexColumnWidth(1.25),
          },
          children: <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: <pw.Widget>[
                _headerCell('#'),
                _headerCell('Item'),
                _headerCell('HSN/SAC'),
                _headerCell('Tax'),
                _headerCell('Qty'),
                _headerCell('Rate / Item'),
                _headerCell('Per'),
                _headerCell('Amount'),
              ],
            ),
            ...items.asMap().entries.map(
                  (MapEntry<int, TyreBillItem> entry) {
                final int index = entry.key;
                final TyreBillItem item = entry.value;

                return pw.TableRow(
                  children: <pw.Widget>[
                    _cell('${index + 1}', align: pw.Alignment.center),
                    _itemCell(item),
                    _cell(_hsnCode, align: pw.Alignment.center),
                    _cell(
                      '${(bill.sgstRate + bill.cgstRate).toStringAsFixed(0)}%',
                      align: pw.Alignment.center,
                    ),
                    _cell(
                      _number(item.quantity),
                      align: pw.Alignment.center,
                    ),
                    _cell(
                      _money(item.rate),
                      align: pw.Alignment.centerRight,
                    ),
                    _cell('PCS', align: pw.Alignment.center),
                    _cell(
                      _money(item.amount),
                      align: pw.Alignment.centerRight,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the item cell in the same compact multi-line style as the
  /// reference invoice.
  pw.Widget _itemCell(TyreBillItem item) {
    final String firstLine =
        '${item.franchise} - ${item.tyre}';

    final String secondLine =
    '${item.pattern} ${item.size}'.trim();

    final List<String> details = <String>[
      firstLine,
      secondLine,
      'Vehicle: ${item.vehicleType}',
    ];

    return _cell(
      details.join('\n'),
      bold: true,
    );
  }

  // ---------------------------------------------------------------------------
  // TOTALS
  // ---------------------------------------------------------------------------

  pw.Widget _buildTotals(TyreBill bill) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 255,
        child: pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey500,
            width: 0.6,
          ),
          children: <pw.TableRow>[
            _totalRow(
              'Taxable Amount',
              _money(bill.taxableAmount),
            ),
            _totalRow(
              'CGST ${bill.cgstRate.toStringAsFixed(1)}%',
              _money(bill.cgstAmount),
            ),
            _totalRow(
              'SGST ${bill.sgstRate.toStringAsFixed(1)}%',
              _money(bill.sgstAmount),
            ),
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              children: <pw.Widget>[
                _cell('TOTAL', bold: true),
                _cell(
                  _money(bill.grandTotal),
                  bold: true,
                  align: pw.Alignment.centerRight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AMOUNT IN WORDS
  // ---------------------------------------------------------------------------

  pw.Widget _buildAmountInWords(TyreBill bill) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey500,
          width: 0.6,
        ),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: <pw.TextSpan>[
            pw.TextSpan(
              text: 'Amount Chargeable (in words): ',
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: 'INR ${_amountInWords(bill.grandTotal)} Only. E & O.E',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAYMENT
  // ---------------------------------------------------------------------------

  pw.Widget _buildPaymentSection(TyreBill bill) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey500,
          width: 0.6,
        ),
      ),
      padding: const pw.EdgeInsets.all(7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'Payment Information',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                _labelValue('Payment Method', bill.paymentMethod),
                if (bill.remarks.trim().isNotEmpty)
                  _labelValue('Remarks', bill.remarks.trim()),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            width: 150,
            alignment: pw.Alignment.center,
            child: pw.Column(
              children: <pw.Widget>[
                pw.SizedBox(height: 24),
                pw.Container(
                  width: 130,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColors.grey700,
                        width: 0.7,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SIGNATURE SECTION
  // ---------------------------------------------------------------------------

  pw.Widget _buildSignatureSection() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'This is a computer generated document and requires no signature.',
        style: const pw.TextStyle(
          fontSize: 6.5,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON SECTION TITLE
  // ---------------------------------------------------------------------------

  pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMMON TABLE CELL
  // ---------------------------------------------------------------------------

  pw.Widget _cell(
      String text, {
        bool bold = false,
        pw.Alignment align = pw.Alignment.centerLeft,
      }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),
      alignment: align,
      child: pw.Text(
        text,
        textAlign: align == pw.Alignment.centerRight
            ? pw.TextAlign.right
            : align == pw.Alignment.center
            ? pw.TextAlign.center
            : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 6.8,
          fontWeight: bold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TABLE HEADER CELL
  // ---------------------------------------------------------------------------

  pw.Widget _headerCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 5,
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TOTAL ROW
  // ---------------------------------------------------------------------------

  pw.TableRow _totalRow(
      String label,
      String value,
      ) {
    return pw.TableRow(
      children: <pw.Widget>[
        _cell(label, bold: true),
        _cell(
          value,
          align: pw.Alignment.centerRight,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NUMBER FORMAT
  // ---------------------------------------------------------------------------

  String _number(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  // ---------------------------------------------------------------------------
  // INDIAN CURRENCY WORDS
  // ---------------------------------------------------------------------------

  String _amountInWords(double amount) {
    final int rupees = amount.floor();
    final int paise = ((amount - rupees) * 100).round();

    final String rupeeWords = _numberToIndianWords(rupees);

    if (paise == 0) {
      return '$rupeeWords Rupees';
    }

    final String paiseWords = _numberToIndianWords(paise);
    return '$rupeeWords Rupees and $paiseWords Paise';
  }

  String _numberToIndianWords(int number) {
    if (number == 0) {
      return 'Zero';
    }

    if (number < 0) {
      return 'Minus ${_numberToIndianWords(-number)}';
    }

    final List<String> parts = <String>[];

    final int crore = number ~/ 10000000;
    final int afterCrore = number % 10000000;
    final int lakh = afterCrore ~/ 100000;
    final int afterLakh = afterCrore % 100000;
    final int thousand = afterLakh ~/ 1000;
    final int remainder = afterLakh % 1000;

    if (crore > 0) {
      parts.add('${_underThousand(crore)} Crore');
    }

    if (lakh > 0) {
      parts.add('${_underThousand(lakh)} Lakh');
    }

    if (thousand > 0) {
      parts.add('${_underThousand(thousand)} Thousand');
    }

    if (remainder > 0) {
      parts.add(_underThousand(remainder));
    }

    return parts.join(' ');
  }

  String _underThousand(int number) {
    const List<String> ones = <String>[
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];

    const List<String> tens = <String>[
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number < 20) {
      return ones[number];
    }

    if (number < 100) {
      final int ten = number ~/ 10;
      final int one = number % 10;
      return one == 0 ? tens[ten] : '${tens[ten]} ${ones[one]}';
    }

    final int hundred = number ~/ 100;
    final int remainder = number % 100;

    if (remainder == 0) {
      return '${ones[hundred]} Hundred';
    }

    return '${ones[hundred]} Hundred ${_underThousand(remainder)}';
  }
}

// -----------------------------------------------------------------------------
// PDF FONT HOLDER
// -----------------------------------------------------------------------------

class _PdfFonts {
  const _PdfFonts({
    required this.regular,
    required this.bold,
  });

  final pw.Font regular;
  final pw.Font bold;
}
