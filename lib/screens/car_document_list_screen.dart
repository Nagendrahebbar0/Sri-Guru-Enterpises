// ============================================================
// FILE: car_document_list_screen.dart
//
// PURPOSE:
// Displays all Car Documents for Sri Guru Enterprises.
//
// FEATURES:
// - Shows all Car Documents.
// - Search by document type.
// - Search by other state name.
// - Search by customer name.
// - Search by customer number.
// - Search by vehicle number.
// - Shows expiry status.
// - Shows Income, Expense and Profit.
// - Edit document.
// - Duplicate document.
// - Delete document.
// - Opens Add Car Document screen.
// - Sends expiry reminder through normal SMS app.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/car_document.dart';
import '../repositories/car_document_repository.dart';
import '../services/sms_service.dart';
import 'add_edit_car_document_screen.dart';

// ============================================================
// CAR DOCUMENT LIST SCREEN
// ============================================================

class CarDocumentListScreen extends StatefulWidget {
  const CarDocumentListScreen({
    super.key,
  });

  @override
  State<CarDocumentListScreen> createState() =>
      _CarDocumentListScreenState();
}

// ============================================================
// STATE
// ============================================================

class _CarDocumentListScreenState
    extends State<CarDocumentListScreen> {
  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final CarDocumentRepository _repository =
  CarDocumentRepository();

  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // DOCUMENT LIST
  // ------------------------------------------------------------

  List<CarDocument> _documents = <CarDocument>[];

  // ------------------------------------------------------------
  // LOADING
  // ------------------------------------------------------------

  bool _isLoading = true;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDocuments();

    _searchController.addListener(
      _onSearchChanged,
    );
  }

  // ============================================================
  // LOAD DOCUMENTS
  // ============================================================

  Future<void> _loadDocuments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<CarDocument> documents =
      await _repository.getCarDocuments();

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load Car Documents.',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    final String query =
    _searchController.text.trim();

    if (query.isEmpty) {
      _loadDocuments();
      return;
    }

    _searchDocuments(query);
  }

  Future<void> _searchDocuments(
      String query,
      ) async {
    try {
      final List<CarDocument> documents =
      await _repository.searchCarDocuments(query);

      if (!mounted) {
        return;
      }

      setState(() {
        _documents = documents;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to search Car Documents.',
      );
    }
  }

  // ============================================================
  // ADD DOCUMENT
  // ============================================================

  Future<void> _addDocument() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const AddEditCarDocumentScreen(),
      ),
    );

    await _loadDocuments();
  }

  // ============================================================
  // EDIT DOCUMENT
  // ============================================================

  Future<void> _editDocument(
      CarDocument document,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEditCarDocumentScreen(
              carDocument: document,
            ),
      ),
    );

    await _loadDocuments();
  }

  // ============================================================
  // DUPLICATE DOCUMENT
  // ============================================================

  Future<void> _duplicateDocument(
      CarDocument document,
      ) async {
    try {
      await _repository.duplicateCarDocument(
        document,
      );

      await _loadDocuments();

      _showMessage(
        'Car Document duplicated successfully.',
      );
    } catch (e) {
      _showMessage(
        'Unable to duplicate Car Document.',
      );
    }
  }

  // ============================================================
  // DELETE DOCUMENT
  // ============================================================

  Future<void> _deleteDocument(
      CarDocument document,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Car Document?',
          ),
          content: const Text(
            'Are you sure you want to delete this Car Document?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _repository.deleteCarDocument(
        document.id!,
      );

      await _loadDocuments();

      _showMessage(
        'Car Document deleted successfully.',
      );
    } catch (e) {
      _showMessage(
        'Unable to delete Car Document.',
      );
    }
  }

  // ============================================================
  // SEND SMS REMINDER
  // ============================================================

  Future<void> _sendExpiryReminderSms(
      CarDocument document,
      ) async {
    final String message =
    _buildExpiryReminderMessage(
      document,
    );

    final bool opened =
    await SmsService.openSms(
      phoneNumber: document.customerNumber,
      message: message,
    );

    if (!opened && mounted) {
      _showMessage(
        'Unable to open SMS application.',
      );
    }
  }

  // ============================================================
  // SMS MESSAGE
  // ============================================================

  String _buildExpiryReminderMessage(
      CarDocument document,
      ) {
    final String expiryDate =
    DateFormat('dd/MM/yyyy').format(
      document.expiryDate,
    );

    final String documentName =
    document.documentType == 'Other State Permit' &&
        document.otherStateName != null &&
        document.otherStateName!
            .trim()
            .isNotEmpty
        ? '${document.documentType} (${document.otherStateName})'
        : document.documentType;

    return '''
Dear Customer,

This is a reminder from Sri Guru Enterprises.

Your $documentName for vehicle ${document.vehicleNumber} is due to expire on $expiryDate.

Kindly renew the document before the expiry date.

Thank you,
Sri Guru Enterprises
''';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(DateTime date) {
    return DateFormat(
      'dd/MM/yyyy',
    ).format(date);
  }

  // ============================================================
  // EXPIRY STATUS
  // ============================================================

  int _daysUntilExpiry(
      DateTime expiryDate,
      ) {
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final DateTime expiry = DateTime(
      expiryDate.year,
      expiryDate.month,
      expiryDate.day,
    );

    return expiry
        .difference(today)
        .inDays;
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String _getExpiryStatus(
      CarDocument document,
      ) {
    final int days =
    _daysUntilExpiry(
      document.expiryDate,
    );

    if (days < 0) {
      return 'EXPIRED';
    }

    if (days == 0) {
      return 'DUE TODAY';
    }

    if (days <= 30) {
      return 'EXPIRING SOON';
    }

    return 'VALID';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _getStatusColor(
      CarDocument document,
      ) {
    final int days =
    _daysUntilExpiry(
      document.expiryDate,
    );

    if (days < 0) {
      return Colors.red;
    }

    if (days == 0) {
      return Colors.red;
    }

    if (days <= 30) {
      return Colors.orange;
    }

    return Colors.green;
  }

  // ============================================================
  // SHOULD SHOW SMS BUTTON
  //
  // Reminder timing:
  // 30, 15, 7 and 1 day before expiry.
  // Also show for due today and overdue.
  // ============================================================

  bool _shouldShowSmsButton(
      CarDocument document,
      ) {
    final int days =
    _daysUntilExpiry(
      document.expiryDate,
    );

    return days <= 30 &&
        (days == 30 ||
            days == 15 ||
            days == 7 ||
            days == 1 ||
            days == 0 ||
            days < 0);
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Car Documents',
        ),
      ),

      // ----------------------------------------------------------
      // ADD BUTTON
      // ----------------------------------------------------------

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _addDocument,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Document',
        ),
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: Column(
        children: <Widget>[
          // ======================================================
          // SEARCH BAR
          // ======================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              8,
            ),
            child: TextField(
              controller:
              _searchController,
              decoration:
              InputDecoration(
                hintText:
                'Search documents...',
                prefixIcon:
                const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchController
                    .text
                    .isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController
                        .clear();
                  },
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
          ),

          // ======================================================
          // DOCUMENT LIST
          // ======================================================

          Expanded(
            child: _buildDocumentList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOCUMENT LIST
  // ============================================================

  Widget _buildDocumentList() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_documents.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding:
        const EdgeInsets.fromLTRB(
          12,
          4,
          12,
          100,
        ),
        itemCount:
        _documents.length,
        itemBuilder:
            (
            BuildContext context,
            int index,
            ) {
          final CarDocument document =
          _documents[index];

          return _buildDocumentCard(
            document,
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool hasSearch =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: <Widget>[
            Icon(
              hasSearch
                  ? Icons.search_off
                  : Icons.description_outlined,
              size: 64,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              hasSearch
                  ? 'No Car Documents found.'
                  : 'No Car Documents added yet.',
              textAlign:
              TextAlign.center,
              style:
              Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT CARD
  // ============================================================

  Widget _buildDocumentCard(
      CarDocument document,
      ) {
    final Color statusColor =
    _getStatusColor(
      document,
    );

    final String status =
    _getExpiryStatus(
      document,
    );

    final int days =
    _daysUntilExpiry(
      document.expiryDate,
    );

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            // ==================================================
            // HEADER
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    document.documentType ==
                        'Other State Permit' &&
                        document.otherStateName !=
                            null &&
                        document.otherStateName!
                            .trim()
                            .isNotEmpty
                        ? '${document.documentType} (${document.otherStateName})'
                        : document.documentType,
                    style:
                    Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                // ----------------------------------------------
                // STATUS BADGE
                // ----------------------------------------------

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    status,
                    style:
                    TextStyle(
                      color:
                      statusColor,
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // CUSTOMER
            // ==================================================

            _buildInfoRow(
              Icons.person_outline,
              'Customer',
              document.customerName,
            ),

            const SizedBox(
              height: 6,
            ),

            _buildInfoRow(
              Icons.phone_outlined,
              'Customer Number',
              document.customerNumber,
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // VEHICLE
            // ==================================================

            _buildInfoRow(
              Icons.directions_car_outlined,
              'Vehicle Number',
              document.vehicleNumber,
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // DOCUMENT DATE
            // ==================================================

            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Date',
              _formatDate(
                document.date,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // EXPIRY DATE
            // ==================================================

            _buildInfoRow(
              Icons.event_busy_outlined,
              'Expiry Date',
              _formatDate(
                document.expiryDate,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // DAYS REMAINING
            // ==================================================

            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(10),
              decoration:
              BoxDecoration(
                color:
                statusColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
              ),
              child: Text(
                days < 0
                    ? '${days.abs()} day(s) overdue'
                    : days == 0
                    ? 'Document expires today'
                    : '$days day(s) remaining',
                style:
                TextStyle(
                  color:
                  statusColor,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // FINANCIAL DETAILS
            // ==================================================

            Row(
              children: <Widget>[
                Expanded(
                  child:
                  _buildAmountColumn(
                    'Income',
                    document.income,
                  ),
                ),
                Expanded(
                  child:
                  _buildAmountColumn(
                    'Expense',
                    document.expense,
                  ),
                ),
                Expanded(
                  child:
                  _buildAmountColumn(
                    'Profit',
                    document.profit,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // PAYMENT
            // ==================================================

            _buildInfoRow(
              Icons.payments_outlined,
              'Payment',
              document.paymentMethod,
            ),

            // ==================================================
            // BBTDU ID
            // ==================================================

            if (document.bbtdUIdNo != null &&
                document.bbtdUIdNo!
                    .trim()
                    .isNotEmpty) ...<Widget>[
              const SizedBox(
                height: 6,
              ),
              _buildInfoRow(
                Icons.badge_outlined,
                'BBTDU ID No.',
                document.bbtdUIdNo!,
              ),
            ],

            const SizedBox(
              height: 12,
            ),

            const Divider(),

            // ==================================================
            // ACTION BUTTONS
            // ==================================================

            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                // ----------------------------------------------
                // EDIT
                // ----------------------------------------------

                TextButton.icon(
                  onPressed: () =>
                      _editDocument(
                        document,
                      ),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label:
                  const Text('Edit'),
                ),

                // ----------------------------------------------
                // DUPLICATE
                // ----------------------------------------------

                TextButton.icon(
                  onPressed: () =>
                      _duplicateDocument(
                        document,
                      ),
                  icon: const Icon(
                    Icons.copy_outlined,
                  ),
                  label:
                  const Text('Duplicate'),
                ),

                // ----------------------------------------------
                // DELETE
                // ----------------------------------------------

                TextButton.icon(
                  onPressed: () =>
                      _deleteDocument(
                        document,
                      ),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  label:
                  const Text('Delete'),
                ),

                // ----------------------------------------------
                // SMS
                // ----------------------------------------------

                if (_shouldShowSmsButton(
                  document,
                ))
                  FilledButton.icon(
                    onPressed: () =>
                        _sendExpiryReminderSms(
                          document,
                        ),
                    icon: const Icon(
                      Icons.sms_outlined,
                    ),
                    label:
                    const Text(
                      'Send Reminder',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  //
  // IMPORTANT:
  // Explicit text styles are used here instead of inheriting
  // the complete DefaultTextStyle.
  //
  // This prevents abnormal font size, color and decoration
  // from being applied to Customer, Customer Number,
  // Vehicle Number, Date and other information.
  // ============================================================

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 19,
        ),

        const SizedBox(
          width: 8,
        ),

        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w600,
                    decoration:
                    TextDecoration.none,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.normal,
                    decoration:
                    TextDecoration.none,
                  ),
                ),
              ],
            ),
            maxLines: 3,
            overflow:
            TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // AMOUNT COLUMN
  // ============================================================

  Widget _buildAmountColumn(
      String label,
      double amount,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style:
          Theme.of(context)
              .textTheme
              .bodySmall,
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController
        .removeListener(
      _onSearchChanged,
    );

    _searchController.dispose();

    super.dispose();
  }
}