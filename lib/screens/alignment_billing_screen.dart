// ============================================================
// FILE: alignment_billing_screen.dart
//
// PURPOSE:
// Main screen for Simple Alignment Billing.
//
// FEATURES:
// - Display all Alignment Bills.
// - Search bills.
// - Add new bill.
// - Edit bill.
// - Duplicate bill.
// - Delete bill.
// - Newest bills appear first.
//
// IMPORTANT:
// - Alignment Billing does NOT use GST.
// - Existing modules are not modified here.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alignment_bill.dart';
import '../repositories/alignment_bill_repository.dart';
import 'alignment_bill_add_edit_screen.dart';
import 'alignment_bill_preview_screen.dart';

class AlignmentBillingScreen extends StatefulWidget {
  const AlignmentBillingScreen({
    super.key,
  });

  @override
  State<AlignmentBillingScreen> createState() =>
      _AlignmentBillingScreenState();
}

class _AlignmentBillingScreenState
    extends State<AlignmentBillingScreen> {
  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final AlignmentBillRepository _repository =
  AlignmentBillRepository();

  // ------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  List<AlignmentBill> _bills = <AlignmentBill>[];

  bool _loading = true;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadBills();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD BILLS
  // ============================================================

  Future<void> _loadBills() async {
    setState(() {
      _loading = true;
    });

    try {
      final String searchText =
      _searchController.text.trim();

      final List<AlignmentBill> bills;

      if (searchText.isEmpty) {
        bills = await _repository.getAllBills();
      } else {
        bills = await _repository.searchBills(searchText);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _bills = bills;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _showError(
        'Unable to load Alignment Bills.\n$error',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    _loadBills();
  }

  // ============================================================
  // ADD BILL
  // ============================================================

  Future<void> _addBill() async {
    final bool? saved =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return const AlignmentBillAddEditScreen();
        },
      ),
    );

    if (saved == true && mounted) {
      await _loadBills();
    }
  }

  // ============================================================
  // EDIT BILL
  // ============================================================

  Future<void> _editBill(AlignmentBill bill) async {
    final bool? saved =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return AlignmentBillAddEditScreen(
            bill: bill,
          );
        },
      ),
    );

    if (saved == true && mounted) {
      await _loadBills();
    }
  }

  // ============================================================
  // PREVIEW BILL
  // ============================================================

  Future<void> _previewBill(AlignmentBill bill) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return AlignmentBillPreviewScreen(
            bill: bill,
          );
        },
      ),
    );
  }

  // ============================================================
  // DUPLICATE BILL
  // ============================================================
  //
  // Opens the Add/Edit screen in duplicate mode.
  //
  // The Add/Edit screen generates the next unique bill number.
  // This prevents the UNIQUE constraint error that occurred when
  // the original bill number was inserted again.
  // ============================================================
  //
   Future<void> _duplicateBill(AlignmentBill bill) async {
     try {
       final bool? saved =
           await Navigator.of(context).push<bool>(
         MaterialPageRoute<bool>(
           builder: (BuildContext context) {
             return AlignmentBillAddEditScreen(
             bill: bill,
             isDuplicate: true,
             );
           },
         ),
       );

       if (saved != true) {
         return;
       }

  // ----------------------------------------------------------
  // Check that this screen is still mounted BEFORE using
  // BuildContext after the asynchronous navigation operation.
  // ----------------------------------------------------------
  //
      if (!mounted) {
       return;
       }

  // Show the message before another await.
  //
  // This prevents the analyzer warning:
  // "Don't use BuildContext's across async gaps."
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(
           content: Text(
             'Alignment Bill duplicated successfully.',
           ),
         ),
       );

  // ----------------------------------------------------------
  // Reload the list after showing the message.
  // No BuildContext is used after this await.
  // ----------------------------------------------------------
  //
      await _loadBills();
      } catch (error) {
     if (!mounted) {
         return;
       }

       _showError(
         'Unable to duplicate Alignment Bill.\n$error',
       );
     }
   }

  // ============================================================
  // DELETE BILL CONFIRMATION
  // ============================================================

  Future<void> _confirmDelete(
      AlignmentBill bill,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Alignment Bill?',
          ),
          content: Text(
            'Are you sure you want to delete '
                '${bill.billNumber}?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteBill(bill);
    }
  }

  // ============================================================
  // DELETE BILL
  // ============================================================

  Future<void> _deleteBill(
      AlignmentBill bill,
      ) async {
    if (bill.id == null) {
      return;
    }

    try {
      await _repository.deleteBill(
        bill.id!,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Alignment Bill deleted.',
          ),
        ),
      );

      await _loadBills();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to delete Alignment Bill.\n$error',
      );
    }
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
  // BILL CARD
  // ============================================================

  Widget _buildBillCard(
      AlignmentBill bill,
      ) {
    // Light orange card theme, matching the Accessories,
    // Trip Sheet and Bill Book style.
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      color: Colors.orange.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            // --------------------------------------------------
            // TOP ROW
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        bill.billNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(bill.date),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount badge.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₹${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              height: 24,
            ),

            // --------------------------------------------------
            // CUSTOMER
            // --------------------------------------------------

            _infoRow(
              Icons.person_outline,
              'Customer',
              bill.customerName,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.phone_outlined,
              'Customer Number',
              bill.customerNumber,
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // VEHICLE
            // --------------------------------------------------

            _infoRow(
              Icons.directions_car_outlined,
              'Vehicle Number',
              bill.vehicleNumber,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.car_rental_outlined,
              'Vehicle Model',
              bill.vehicleModel,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.speed_outlined,
              'KMS',
              bill.kms.toString(),
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // SERVICE
            // --------------------------------------------------

            _infoRow(
              Icons.car_repair_outlined,
              'Service',
              bill.service,
            ),

            const SizedBox(height: 8),

            _infoRow(
              Icons.payments_outlined,
              'Payment',
              bill.paymentMethod,
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // QUANTITY AND RATE
            // --------------------------------------------------

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  // Quantity
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.format_list_numbered,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Quantity',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bill.quantity.toStringAsFixed(
                                  bill.quantity % 1 == 0 ? 0 : 2,
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Rate
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.currency_rupee,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Rate',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${bill.rate.toStringAsFixed(2)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // ACTION BUTTONS
            // --------------------------------------------------

            const SizedBox(height: 10),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 4),

            // Compact action row.
            //
            // All four actions stay on one horizontal line.
            // Short labels are used to prevent wrapping on small
            // mobile screens.
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.visibility_outlined,
                    label: 'Preview',
                    onPressed: () {
                      _previewBill(bill);
                    },
                  ),
                ),

                Expanded(
                  child: _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onPressed: () {
                      _editBill(bill);
                    },
                  ),
                ),

                Expanded(
                  child: _buildActionButton(
                    icon: Icons.copy_outlined,
                    label: 'Duplicate',
                    onPressed: () {
                      _duplicateBill(bill);
                    },
                  ),
                ),

                // Delete is kept compact because it is an icon-only
                // destructive action.
                SizedBox(
                  width: 42,
                  child: IconButton(
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _confirmDelete(bill);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 21,
                    ),
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
// COMPACT ACTION BUTTON
// ============================================================
//
// Creates a small action button suitable for narrow mobile
// screens. The icon and label remain on a single line.
// ============================================================

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 42,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  // Displays one bill detail in a compact mobile-friendly format.
  // Explicit text styles are used so the row does not inherit
  // unwanted large/red/underlined text from the surrounding theme.
  // ============================================================

  Widget _infoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade700,
        ),

        const SizedBox(width: 8),

        // Label and value are separated so they remain readable
        // even when the value is long.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool searching =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              searching
                  ? Icons.search_off_outlined
                  : Icons.car_repair_outlined,
              size: 64,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 16),
            Text(
              searching
                  ? 'No Alignment Bills Found'
                  : 'No Alignment Bills Yet',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different search.'
                  : 'Add your first Simple Alignment Bill.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
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
          'Alignment Billing',
        ),
      ),

      // --------------------------------------------------------
      // ADD BUTTON
      // --------------------------------------------------------

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBill,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Bill',
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: Column(
        children: <Widget>[
          // ----------------------------------------------------
          // SEARCH BAR
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction:
              TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Search bill, customer, number or vehicle',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchController.text
                    .trim()
                    .isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ----------------------------------------------------
          // BILL COUNT
          // ----------------------------------------------------

          if (!_loading)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Align(
                alignment:
                Alignment.centerLeft,
                child: Text(
                  '${_bills.length} bill'
                      '${_bills.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // ----------------------------------------------------
          // BILL LIST
          // ----------------------------------------------------

          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _bills.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadBills,
              child: ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  100,
                ),
                itemCount: _bills.length,
                itemBuilder:
                    (
                    BuildContext context,
                    int index,
                    ) {
                  return _buildBillCard(
                    _bills[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}