import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/tyre_bill.dart';
import '../models/tyre_bill_item.dart';
import '../repositories/tyre_bill_repository.dart';
import 'tyre_bill_add_edit_screen.dart';
import 'tyre_bill_preview_screen.dart';
/// Displays all Tyre Billing invoices.
///
/// This screen is intentionally kept separate from the Add/Edit screen.
/// It provides searching, viewing, editing, duplication and deletion.
class TyreBillListScreen extends StatefulWidget {
  const TyreBillListScreen({super.key});

  @override
  State<TyreBillListScreen> createState() => _TyreBillListScreenState();
}

class _TyreBillListScreenState extends State<TyreBillListScreen> {
  final TyreBillRepository _repository = TyreBillRepository();
  final TextEditingController _searchController = TextEditingController();

  List<TyreBill> _bills = <TyreBill>[];
  bool _isLoading = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadBills();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final String value = _searchController.text.trim();

    if (_searchText == value) {
      return;
    }

    _searchText = value;
    _loadBills();
  }

  Future<void> _loadBills() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<TyreBill> bills = _searchText.isEmpty
          ? await _repository.getAllBills()
          : await _repository.searchBills(_searchText);

      if (!mounted) {
        return;
      }

      setState(() {
        _bills = bills;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load tyre bills: $error');
    }
  }

  Future<void> _addBill() async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return const TyreBillAddEditScreen();
        },
      ),
    );

    if (saved == true) {
      await _loadBills();
    }
  }

  Future<void> _editBill(TyreBill bill) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return TyreBillAddEditScreen(bill: bill);
        },
      ),
    );

    if (saved == true) {
      await _loadBills();
    }
  }

  Future<void> _duplicateBill(TyreBill bill) async {
    if (bill.id == null) {
      _showMessage('This invoice cannot be duplicated.');
      return;
    }

    try {
      final bool? saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (BuildContext context) {
            return TyreBillAddEditScreen(
              bill: bill,
              isDuplicate: true,
            );
          },
        ),
      );

      if (saved == true) {
        await _loadBills();
      }
    } catch (error) {
      _showMessage('Unable to duplicate invoice: $error');
    }
  }

  Future<void> _deleteBill(TyreBill bill) async {
    if (bill.id == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Invoice?'),
          content: Text(
            'Delete invoice ${bill.invoiceNumber}?\n\n'
                'The tyre stock used by this invoice will be restored.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      await _repository.deleteBill(bill.id!);
      await _loadBills();

      if (mounted) {
        _showMessage('Invoice deleted successfully.');
      }
    } catch (error) {
      _showMessage('Unable to delete invoice: $error');
    }
  }

  /// Opens the saved invoice in the professional preview screen.
  Future<void> _viewBill(TyreBill bill) async {
    if (bill.id == null) {
      return;
    }

    try {
      // Load all items belonging to this invoice.
      final List<TyreBillItem> items =
      await _repository.getItemsForBill(bill.id!);

      if (!mounted) {
        return;
      }

      // Open the read-only invoice preview screen.
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return TyreBillPreviewScreen(
              bill: bill,
              items: items,
            );
          },
        ),
      );
    } catch (error) {
      _showMessage('Unable to open invoice: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tyre Billing'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Search invoice, customer, number or vehicle',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear search',
                  onPressed: _searchController.clear,
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBill,
        icon: const Icon(Icons.add),
        label: const Text('Add Tyre Bill'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_bills.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBills,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            const SizedBox(height: 120),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _searchText.isEmpty
                    ? 'No tyre bills yet.'
                    : 'No tyre bills found.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _searchText.isEmpty
                    ? 'Tap Add Tyre Bill to create the first invoice.'
                    : 'Try a different search.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBills,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        itemCount: _bills.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final TyreBill bill = _bills[index];
          return _buildBillCard(bill);
        },
      ),
    );
  }

  Widget _buildBillCard(TyreBill bill) {
    final ThemeData theme = Theme.of(context);
    final bool isGst = bill.billType == 'GST Invoice';

    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _viewBill(bill),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: isGst
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                child: Icon(
                  Icons.receipt_long,
                  color: isGst
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            bill.invoiceNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildTypeBadge(isGst),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      bill.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bill.customerNumber} • ${bill.vehicleNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Text(
                          DateFormat('dd/MM/yyyy').format(bill.date),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bill.paymentMethod,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    '₹${bill.grandTotal.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Invoice actions',
                    onSelected: (String value) {
                      switch (value) {
                        case 'view':
                          _viewBill(bill);
                          break;
                        case 'edit':
                          _editBill(bill);
                          break;
                        case 'duplicate':
                          _duplicateBill(bill);
                          break;
                        case 'delete':
                          _deleteBill(bill);
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'view',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.visibility_outlined),
                            title: Text('View'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'duplicate',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.copy_outlined),
                            title: Text('Duplicate'),
                          ),
                        ),
                        PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(bool isGst) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: isGst
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isGst ? 'GST' : 'Non-GST',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
