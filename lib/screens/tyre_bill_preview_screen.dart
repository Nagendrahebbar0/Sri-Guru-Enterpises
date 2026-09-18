import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../models/tyre_bill.dart';
import '../models/tyre_bill_item.dart';
import '../services/tyre_bill_pdf_service.dart';

/// Professional read-only preview of a saved Tyre Bill.
///
/// This screen does not modify the database or perform calculations.
/// It displays the values already saved in the TyreBill and TyreBillItem
/// objects, including the tax-inclusive rate and saved GST amounts.
///
/// PDF, Share and Print actions use the existing TyreBillPdfService.
class TyreBillPreviewScreen extends StatefulWidget {
  final TyreBill bill;
  final List<TyreBillItem> items;

  const TyreBillPreviewScreen({
    super.key,
    required this.bill,
    required this.items,
  });

  @override
  State<TyreBillPreviewScreen> createState() =>
      _TyreBillPreviewScreenState();
}

/// State class used to manage PDF action progress.
class _TyreBillPreviewScreenState extends State<TyreBillPreviewScreen> {
  /// Existing PDF service responsible for generating the invoice PDF.
  final TyreBillPdfService _pdfService = TyreBillPdfService.instance;

  /// Prevents multiple PDF actions from being started at the same time.
  bool _isProcessingPdf = false;

  /// Shortcut for the saved bill.
  TyreBill get bill => widget.bill;

  /// Shortcut for the saved invoice items.
  List<TyreBillItem> get items => widget.items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isGst = bill.billType == 'GST Invoice';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(theme),
                const SizedBox(height: 18),
                const Divider(),
                const SizedBox(height: 14),
                _buildInvoiceInfo(theme, isGst),
                const SizedBox(height: 18),
                _buildCustomerSection(theme),
                const SizedBox(height: 18),
                _buildItemsSection(theme),
                const SizedBox(height: 18),
                _buildTotalsSection(theme),
                const SizedBox(height: 18),
                _buildPaymentSection(theme),
                if (bill.remarks.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  _buildRemarksSection(theme),
                ],
                const SizedBox(height: 24),

                // PDF action buttons.
                _buildPdfActions(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PDF ACTIONS
  // ============================================================

  /// Builds Download PDF, Share PDF and Print buttons.
  Widget _buildPdfActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Invoice Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        // Download PDF button.
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: _isProcessingPdf ? null : _downloadPdf,
            icon: const Icon(Icons.download_outlined),
            label: const Text('Download PDF'),
          ),
        ),

        const SizedBox(height: 10),

        // Share PDF button.
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isProcessingPdf ? null : _sharePdf,
            icon: const Icon(Icons.share_outlined),
            label: const Text('Share PDF'),
          ),
        ),

        const SizedBox(height: 10),

        // Print button.
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isProcessingPdf ? null : _printPdf,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
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

  /// Generates the PDF and saves it in the application's documents folder.
  Future<void> _downloadPdf() async {
    if (_isProcessingPdf) {
      return;
    }

    setState(() {
      _isProcessingPdf = true;
    });

    try {
      final file = await _pdfService.exportBill(
        bill: bill,
        items: items,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'PDF saved successfully:\n${file.path}',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to create PDF: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  /// Generates the PDF and opens the Android share sheet.
  Future<void> _sharePdf() async {
    if (_isProcessingPdf) {
      return;
    }

    setState(() {
      _isProcessingPdf = true;
    });

    try {
      await _pdfService.shareBill(
        bill: bill,
        items: items,
      );

      if (!mounted) {
        return;
      }

      _showMessage('Share sheet opened successfully.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to share PDF: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  /// Opens the system print dialog for the invoice PDF.
  Future<void> _printPdf() async {
    if (_isProcessingPdf) {
      return;
    }

    setState(() {
      _isProcessingPdf = true;
    });

    try {
      // Build the same PDF used for download/share.
      final pdfBytes = await _pdfService.buildPdf(
        bill: bill,
        items: items,
      );

      if (!mounted) {
        return;
      }

      // Open the platform print dialog.
      await Printing.layoutPdf(
        onLayout: (_) async {
          return pdfBytes;
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to print PDF: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPdf = false;
        });
      }
    }
  }

  /// Displays a floating message to the user.
  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  // ============================================================
  // HEADER
  // ============================================================

  /// Builds the business heading shown at the top of the invoice.
  Widget _buildHeader(ThemeData theme) {
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            'SRI GURU ENTERPRISES',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TYRE BILLING',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INVOICE INFORMATION
  // ============================================================

  /// Builds invoice number, invoice type and date information.
  Widget _buildInvoiceInfo(
      ThemeData theme,
      bool isGst,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _infoRow(
            'Invoice Number',
            bill.invoiceNumber,
            bold: true,
          ),
          _infoRow(
            'Invoice Type',
            bill.billType,
          ),
          if (isGst &&
              bill.gstInvoiceNumber?.trim().isNotEmpty == true)
            _infoRow(
              'GST Invoice Number',
              bill.gstInvoiceNumber!,
            ),
          _infoRow(
            'Date',
            DateFormat('dd/MM/yyyy').format(bill.date),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CUSTOMER SECTION
  // ============================================================

  /// Builds customer and vehicle information.
  Widget _buildCustomerSection(ThemeData theme) {
    return _section(
      theme,
      title: 'Customer Details',
      icon: Icons.person_outline,
      child: Column(
        children: <Widget>[
          _infoRow(
            'Customer Name',
            bill.customerName,
          ),
          _infoRow(
            'Customer Number',
            bill.customerNumber,
          ),
          if (bill.address?.trim().isNotEmpty == true)
            _infoRow(
              'Address',
              bill.address!,
            ),
          _infoRow(
            'Vehicle Number',
            bill.vehicleNumber,
          ),
          _infoRow(
            'Vehicle Model',
            bill.vehicleModel,
          ),
          _infoRow(
            'KMS',
            bill.kms.toString(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TYRE ITEMS
  // ============================================================

  /// Builds the complete list of tyres included in the invoice.
  Widget _buildItemsSection(ThemeData theme) {
    return _section(
      theme,
      title: 'Tyre Items',
      icon: Icons.tire_repair_outlined,
      child: Column(
        children: <Widget>[
          ...items.asMap().entries.map(
                (MapEntry<int, TyreBillItem> entry) {
              return _buildItemCard(
                theme,
                entry.key + 1,
                entry.value,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds one invoice item with all stock information and pricing.
  Widget _buildItemCard(
      ThemeData theme,
      int itemNumber,
      TyreBillItem item,
      ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  '$itemNumber. ${item.franchise} ${item.tyre}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'HSN ${TyreBillItem.hsnCode}',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _itemDetailRow(
            'Vehicle Type',
            item.vehicleType,
          ),
          _itemDetailRow(
            'Pattern',
            item.pattern,
          ),
          _itemDetailRow(
            'Size',
            item.size,
          ),
          _itemDetailRow(
            'Quantity',
            _formatNumber(item.quantity),
          ),
          _itemDetailRow(
            'Rate (Inclusive of GST)',
            '₹${item.rate.toStringAsFixed(2)}',
          ),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Amount (Including GST)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '₹${item.amount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOTALS
  // ============================================================

  /// Builds the saved tax breakdown and grand total.
  Widget _buildTotalsSection(ThemeData theme) {
    return _section(
      theme,
      title: 'Tax & Total',
      icon: Icons.calculate_outlined,
      child: Column(
        children: <Widget>[
          _infoRow(
            'Taxable Amount',
            '₹${bill.taxableAmount.toStringAsFixed(2)}',
          ),
          _infoRow(
            'SGST (${bill.sgstRate.toStringAsFixed(2)}%)',
            '₹${bill.sgstAmount.toStringAsFixed(2)}',
          ),
          _infoRow(
            'CGST (${bill.cgstRate.toStringAsFixed(2)}%)',
            '₹${bill.cgstAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Grand Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '₹${bill.grandTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  /// Builds payment information.
  Widget _buildPaymentSection(ThemeData theme) {
    return _section(
      theme,
      title: 'Payment',
      icon: Icons.payments_outlined,
      child: _infoRow(
        'Payment Method',
        bill.paymentMethod,
      ),
    );
  }

  // ============================================================
  // REMARKS
  // ============================================================

  /// Builds remarks when remarks were saved with the invoice.
  Widget _buildRemarksSection(ThemeData theme) {
    return _section(
      theme,
      title: 'Remarks',
      icon: Icons.notes_outlined,
      child: Text(
        bill.remarks,
        style: theme.textTheme.bodyLarge,
      ),
    );
  }

  // ============================================================
  // COMMON UI HELPERS
  // ============================================================

  /// Reusable section container.
  Widget _section(
      ThemeData theme, {
        required String title,
        required IconData icon,
        required Widget child,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              size: 21,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  /// Reusable two-column information row.
  Widget _infoRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight:
                bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight:
                bold ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact detail row used inside each tyre item.
  Widget _itemDetailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Shows whole numbers without an unnecessary decimal portion.
  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}