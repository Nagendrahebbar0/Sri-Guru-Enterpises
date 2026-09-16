// ============================================================
// FILE: alignment_bill_preview_screen.dart
//
// PURPOSE:
// Displays a saved Alignment Bill in a professional,
// read-only preview.
//
// ACTIONS:
// - Download PDF
// - Share PDF
// - Print PDF
//
// IMPORTANT:
// This screen does not modify the database.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import '../models/alignment_bill.dart';
import '../services/alignment_bill_pdf_service.dart';

/// Read-only preview of an Alignment Bill.
class AlignmentBillPreviewScreen extends StatefulWidget {
  final AlignmentBill bill;

  const AlignmentBillPreviewScreen({
    super.key,
    required this.bill,
  });

  @override
  State<AlignmentBillPreviewScreen> createState() =>
      _AlignmentBillPreviewScreenState();
}

class _AlignmentBillPreviewScreenState
    extends State<AlignmentBillPreviewScreen> {
  // ------------------------------------------------------------
  // PDF SERVICE
  // ------------------------------------------------------------

  final AlignmentBillPdfService _pdfService =
      AlignmentBillPdfService.instance;

  // ------------------------------------------------------------
  // PDF PROCESSING STATE
  // ------------------------------------------------------------

  bool _isProcessingPdf = false;

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final AlignmentBill bill = widget.bill;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alignment Bill Preview'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          24,
        ),

        child: Card(
          elevation: 2,

          clipBehavior: Clip.antiAlias,

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: <Widget>[
                // ------------------------------------------------
                // HEADER
                // ------------------------------------------------

                _buildHeader(theme),

                const SizedBox(height: 18),

                const Divider(),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // BILL INFORMATION
                // ------------------------------------------------

                _buildBillInformation(
                  theme,
                  bill,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // CUSTOMER
                // ------------------------------------------------

                _buildCustomerInformation(
                  theme,
                  bill,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // VEHICLE
                // ------------------------------------------------

                _buildVehicleInformation(
                  theme,
                  bill,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // SERVICE
                // ------------------------------------------------

                _buildServiceInformation(
                  theme,
                  bill,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // TOTAL
                // ------------------------------------------------

                _buildTotal(
                  theme,
                  bill,
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // PAYMENT
                // ------------------------------------------------

                _buildPaymentInformation(
                  theme,
                  bill,
                ),

                // ------------------------------------------------
                // REMARKS
                // ------------------------------------------------

                if (bill.remarks.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),

                  _buildRemarks(
                    theme,
                    bill,
                  ),
                ],

                const SizedBox(height: 24),

                // ------------------------------------------------
                // PDF ACTIONS
                // ------------------------------------------------

                _buildPdfActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.center,

      children: <Widget>[
        const Icon(
          Icons.car_repair,
          size: 42,
        ),

        const SizedBox(height: 8),

        Text(
          'SRI GURU ENTERPRISES',
          textAlign: TextAlign.center,

          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'ALIGNMENT BILL',
          textAlign: TextAlign.center,

          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Wheel Alignment Service',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  // ============================================================
  // BILL INFORMATION
  // ============================================================

  Widget _buildBillInformation(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Bill Information',

      children: <Widget>[
        _infoRow(
          theme,
          'Bill Number',
          bill.billNumber,
        ),

        _infoRow(
          theme,
          'Date',
          DateFormat('dd/MM/yyyy').format(
            bill.date,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CUSTOMER INFORMATION
  // ============================================================

  Widget _buildCustomerInformation(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Customer Information',

      children: <Widget>[
        _infoRow(
          theme,
          'Customer Name',
          bill.customerName,
        ),

        _infoRow(
          theme,
          'Customer Number',
          bill.customerNumber,
        ),

        if ((bill.address ?? '').trim().isNotEmpty)
          _infoRow(
            theme,
            'Address',
            bill.address!.trim(),
          ),
      ],
    );
  }

  // ============================================================
  // VEHICLE INFORMATION
  // ============================================================

  Widget _buildVehicleInformation(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Vehicle Information',

      children: <Widget>[
        _infoRow(
          theme,
          'Vehicle Number',
          bill.vehicleNumber,
        ),

        _infoRow(
          theme,
          'KMS',
          bill.kms.toString(),
        ),
      ],
    );
  }

  // ============================================================
  // SERVICE INFORMATION
  // ============================================================

  Widget _buildServiceInformation(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Service Details',

      children: <Widget>[
        _infoRow(
          theme,
          'Service',
          bill.service,
        ),

        _infoRow(
          theme,
          'Quantity',
          _formatNumber(bill.quantity),
        ),

        _infoRow(
          theme,
          'Rate',
          _money(bill.rate),
        ),

        _infoRow(
          theme,
          'Amount',
          _money(bill.amount),
        ),
      ],
    );
  }

  // ============================================================
  // TOTAL
  // ============================================================

  Widget _buildTotal(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return Card(
      elevation: 0,

      color: theme.colorScheme.primaryContainer,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'TOTAL AMOUNT',

                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Text(
              _money(bill.amount),

              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentInformation(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Payment Information',

      children: <Widget>[
        _infoRow(
          theme,
          'Payment Method',
          bill.paymentMethod,
        ),
      ],
    );
  }

  // ============================================================
  // REMARKS
  // ============================================================

  Widget _buildRemarks(
      ThemeData theme,
      AlignmentBill bill,
      ) {
    return _sectionCard(
      title: 'Remarks',

      children: <Widget>[
        Text(
          bill.remarks.trim(),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  // ============================================================
  // PDF ACTIONS
  // ============================================================

  Widget _buildPdfActions(ThemeData theme) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: <Widget>[
        Text(
          'Bill Actions',

          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // DOWNLOAD PDF
        // ------------------------------------------------------

        FilledButton.icon(
          onPressed: _isProcessingPdf
              ? null
              : _exportPdf,

          icon: const Icon(
            Icons.picture_as_pdf_outlined,
          ),

          label: const Text(
            'Download PDF',
          ),
        ),

        const SizedBox(height: 10),

        // ------------------------------------------------------
        // SHARE PDF
        // ------------------------------------------------------

        OutlinedButton.icon(
          onPressed: _isProcessingPdf
              ? null
              : _sharePdf,

          icon: const Icon(
            Icons.share_outlined,
          ),

          label: const Text(
            'Share PDF',
          ),
        ),

        const SizedBox(height: 10),

        // ------------------------------------------------------
        // PRINT
        // ------------------------------------------------------

        OutlinedButton.icon(
          onPressed: _isProcessingPdf
              ? null
              : _printPdf,

          icon: const Icon(
            Icons.print_outlined,
          ),

          label: const Text(
            'Print',
          ),
        ),

        if (_isProcessingPdf) ...<Widget>[
          const SizedBox(height: 14),

          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // EXPORT PDF
  // ============================================================

  Future<void> _exportPdf() async {
    setState(() {
      _isProcessingPdf = true;
    });

    try {
      final file = await _pdfService.exportBill(
        bill: widget.bill,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF created: ${file.path.split('/').last}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to create PDF.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // SHARE PDF
  // ============================================================

  Future<void> _sharePdf() async {
    setState(() {
      _isProcessingPdf = true;
    });

    try {
      await _pdfService.shareBill(
        bill: widget.bill,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to share PDF.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // PRINT PDF
  // ============================================================

  Future<void> _printPdf() async {
    setState(() {
      _isProcessingPdf = true;
    });

    try {
      final Uint8List bytes =
      await _pdfService.buildPdf(
        bill: widget.bill,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
      );
    } catch (error) {
      if (!mounted) return;

      _showError(
        'Unable to print PDF.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: <Widget>[
            Text(
              title,

              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            ...children,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _infoRow(
      ThemeData theme,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: <Widget>[
          SizedBox(
            width: 125,

            child: Text(
              label,

              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value.trim().isEmpty
                  ? '-'
                  : value.trim(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(double value) {
    return '₹${value.toStringAsFixed(2)}';
  }

  // ============================================================
  // NUMBER
  // ============================================================

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }
}