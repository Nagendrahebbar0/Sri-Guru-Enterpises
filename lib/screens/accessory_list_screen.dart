// ============================================================
// FILE: accessory_list_screen.dart
//
// PURPOSE:
// Displays all Accessories stored in SQLite.
//
// FEATURES:
// - Search
// - Add
// - Edit
// - Duplicate
// - Delete
// - Light-orange cards
//
// ITEM VALUES ARE FIXED:
// Trip Sheet, Bill Book, Water Bottle, Tissue Paper,
// Car Perfume, Print Out, Xerox
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/accessory.dart';
import '../repositories/accessory_repository.dart';
import 'add_edit_accessory_screen.dart';

class AccessoryListScreen extends StatefulWidget {
  const AccessoryListScreen({super.key});

  @override
  State<AccessoryListScreen> createState() =>
      _AccessoryListScreenState();
}

class _AccessoryListScreenState extends State<AccessoryListScreen> {
  final AccessoryRepository _repository = AccessoryRepository();
  final TextEditingController _searchController =
      TextEditingController();

  List<Accessory> _accessories = <Accessory>[];
  List<Accessory> _filteredAccessories = <Accessory>[];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_search);
    _loadAccessories();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_search)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadAccessories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Accessory> records =
          await _repository.getAccessories();

      if (!mounted) return;

      setState(() {
        _accessories = records;
        _filteredAccessories = records;
        _isLoading = false;
      });

      _search();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load Accessories: $e'),
        ),
      );
    }
  }

  Future<void> _search() async {
    final String query =
        _searchController.text.trim();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _filteredAccessories =
            List<Accessory>.from(_accessories);
      });
      return;
    }

    try {
      final List<Accessory> results =
          await _repository.searchAccessories(query);

      if (!mounted) return;

      setState(() {
        _filteredAccessories = results;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _filteredAccessories = <Accessory>[];
      });
    }
  }

  Future<void> _addAccessory() async {
    final bool? saved =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            const AddEditAccessoryScreen(),
      ),
    );

    if (saved == true && mounted) {
      await _loadAccessories();
    }
  }

  Future<void> _editAccessory(
    Accessory accessory,
  ) async {
    final bool? saved =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            AddEditAccessoryScreen(
          accessory: accessory,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadAccessories();
    }
  }

  Future<void> _duplicateAccessory(
    Accessory accessory,
  ) async {
    // Duplicate through the Add/Edit screen so the user can
    // review the copied details before saving.
    final bool? saved =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) =>
            AddEditAccessoryScreen(
          accessory: accessory,
          isDuplicate: true,
        ),
      ),
    );

    if (saved == true && mounted) {
      await _loadAccessories();
    }
  }

  Future<void> _deleteAccessory(
    Accessory accessory,
  ) async {
    final bool? confirmed =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Accessory?'),
          content: Text(
            'Delete "${accessory.item}" for '
            '${accessory.customerName}?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || accessory.id == null) {
      return;
    }

    try {
      await _repository.deleteAccessory(
        accessory.id!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accessory deleted.'),
        ),
      );

      await _loadAccessories();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete Accessory: $e'),
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        8,
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
              'Search customer, number, item or remarks...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.trim().isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAccessoryCard(
    Accessory accessory,
  ) {
    final String formattedDate =
        DateFormat('dd/MM/yyyy').format(
      accessory.date,
    );

    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    accessory.item,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        _editAccessory(accessory);
                        break;
                      case 'duplicate':
                        _duplicateAccessory(accessory);
                        break;
                      case 'delete':
                        _deleteAccessory(accessory);
                        break;
                    }
                  },
                  itemBuilder:
                      (BuildContext context) =>
                          const [
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
                        leading:
                            Icon(Icons.copy_outlined),
                        title: Text('Duplicate'),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                        ),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Date',
              formattedDate,
            ),
            _buildInfoRow(
              Icons.person_outline,
              'Customer',
              accessory.customerName,
            ),
            _buildInfoRow(
              Icons.phone_outlined,
              'Number',
              accessory.customerNumber,
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildValue(
                    'Quantity',
                    _formatNumber(
                      accessory.quantity,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildValue(
                    'Rate',
                    '₹${accessory.rate.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildValue(
                    'Total',
                    '₹${accessory.totalAmount.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.payments_outlined,
              'Payment',
              accessory.paymentMethod,
            ),
            if (accessory.remarks.trim().isNotEmpty)
              _buildInfoRow(
                Icons.notes_outlined,
                'Remarks',
                accessory.remarks,
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () =>
                      _editAccessory(accessory),
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _duplicateAccessory(accessory),
                  icon: const Icon(
                    Icons.copy_outlined,
                  ),
                  label: const Text('Duplicate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildValue(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  Widget _buildEmptyState() {
    final bool hasSearch =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'No Accessories found'
                  : 'No Accessories added yet',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!hasSearch) ...[
              const SizedBox(height: 8),
              const Text(
                'Tap + to add Accessories.',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAccessory,
        tooltip: 'Add Accessories',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredAccessories.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAccessories,
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(
                            12,
                            4,
                            12,
                            90,
                          ),
                          itemCount:
                              _filteredAccessories.length,
                          itemBuilder: (
                            BuildContext context,
                            int index,
                          ) {
                            return _buildAccessoryCard(
                              _filteredAccessories[index],
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
