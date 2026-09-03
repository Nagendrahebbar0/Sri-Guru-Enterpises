// ============================================================
// FILE: add_edit_accessory_screen.dart
//
// PURPOSE:
// Add, edit, or duplicate Accessories.
//
// IMPORTANT:
// - Multiple accessory items can be added before saving.
// - The Item dropdown contains exactly the seven approved items.
// - Common customer/date/payment/remarks details apply to all
//   item rows.
// - Customer Name and Number can be typed directly or selected
//   using the search button.
// - Each item is saved as a separate SQLite accessory record.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/accessory.dart';
import '../models/customer.dart';
import '../repositories/accessory_repository.dart';
import '../repositories/customer_repository.dart';

class AddEditAccessoryScreen extends StatefulWidget {
  final Accessory? accessory;
  final List<Accessory>? accessories;
  final bool isDuplicate;

  const AddEditAccessoryScreen({
    super.key,
    this.accessory,
    this.accessories,
    this.isDuplicate = false,
  });

  @override
  State<AddEditAccessoryScreen> createState() =>
      _AddEditAccessoryScreenState();
}

class _AccessoryItemController {
  final TextEditingController quantityController;
  final TextEditingController rateController;

  String? item;

  _AccessoryItemController({
    this.item,
    String quantity = '1',
    String rate = '',
  })  : quantityController = TextEditingController(text: quantity),
        rateController = TextEditingController(text: rate);

  void dispose() {
    quantityController.dispose();
    rateController.dispose();
  }
}

class _AddEditAccessoryScreenState
    extends State<AddEditAccessoryScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AccessoryRepository _accessoryRepository =
      AccessoryRepository();

  final CustomerRepository _customerRepository =
      CustomerRepository();

  final TextEditingController _dateController =
      TextEditingController();

  final TextEditingController _customerNumberController =
      TextEditingController();

  final TextEditingController _customerNameController =
      TextEditingController();

  final TextEditingController _remarksController =
      TextEditingController();

  final List<_AccessoryItemController> _items =
      <_AccessoryItemController>[];

  DateTime _selectedDate = DateTime.now();

  String _paymentMethod = 'Cash';

  bool _isSaving = false;

  static const List<String> _itemOptions = <String>[
    'Trip Sheet',
    'Bill Book',
    'Water Bottle',
    'Tissue Paper',
    'Car Perfume',
    'Print Out',
    'Xerox',
  ];

  bool get _isEditMode =>
      widget.accessory != null && !widget.isDuplicate;

  @override
  void initState() {
    super.initState();

    _selectedDate = widget.accessory?.date ?? DateTime.now();

    _dateController.text =
        DateFormat('dd/MM/yyyy').format(_selectedDate);

    if (widget.accessory != null) {
      final Accessory source = widget.accessory!;

      _customerNumberController.text =
          source.customerNumber;
      _customerNameController.text =
          source.customerName;
      _paymentMethod = source.paymentMethod.isEmpty
          ? 'Cash'
          : source.paymentMethod;
      _remarksController.text = source.remarks;

      _items.add(
        _AccessoryItemController(
          item: source.item,
          quantity: source.quantity.toString(),
          rate: source.rate.toString(),
        ),
      );
    } else if (widget.accessories != null &&
        widget.accessories!.isNotEmpty) {
      final Accessory first = widget.accessories!.first;

      _customerNumberController.text =
          first.customerNumber;
      _customerNameController.text =
          first.customerName;
      _paymentMethod = first.paymentMethod.isEmpty
          ? 'Cash'
          : first.paymentMethod;
      _remarksController.text = first.remarks;

      for (final Accessory accessory in widget.accessories!) {
        _items.add(
          _AccessoryItemController(
            item: accessory.item,
            quantity: accessory.quantity.toString(),
            rate: accessory.rate.toString(),
          ),
        );
      }
    } else {
      _items.add(_AccessoryItemController());
    }

    for (final _AccessoryItemController item in _items) {
      item.quantityController.addListener(_onItemChanged);
      item.rateController.addListener(_onItemChanged);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _customerNumberController.dispose();
    _customerNameController.dispose();
    _remarksController.dispose();

    for (final _AccessoryItemController item in _items) {
      item.dispose();
    }

    super.dispose();
  }

  void _onItemChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  double _parseNumber(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double _getItemTotal(_AccessoryItemController item) {
    final double quantity =
        _parseNumber(item.quantityController.text);
    final double rate =
        _parseNumber(item.rateController.text);

    return Accessory.calculateTotal(
      quantity: quantity,
      rate: rate,
    );
  }

  double get _grandTotal {
    double total = 0;

    for (final _AccessoryItemController item in _items) {
      total += _getItemTotal(item);
    }

    return total;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _dateController.text =
          DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  void _addItem() {
    setState(() {
      final _AccessoryItemController item =
          _AccessoryItemController();

      item.quantityController.addListener(_onItemChanged);
      item.rateController.addListener(_onItemChanged);

      _items.add(item);
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) {
      return;
    }

    final _AccessoryItemController item = _items.removeAt(index);
    item.dispose();

    setState(() {});
  }

  Future<void> _showCustomerPicker() async {
    final TextEditingController searchController =
        TextEditingController();

    List<Customer> customers =
        await _customerRepository.getCustomers();

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        List<Customer> filtered = List<Customer>.from(customers);

        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            void search(String value) {
              final String query = value.trim().toLowerCase();

              setDialogState(() {
                if (query.isEmpty) {
                  filtered = List<Customer>.from(customers);
                } else {
                  filtered = customers.where((Customer customer) {
                    return customer.name
                            .toLowerCase()
                            .contains(query) ||
                        customer.phone
                            .toLowerCase()
                            .contains(query);
                  }).toList();
                }
              });
            }

            return AlertDialog(
              title: const Text('Select Customer'),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: search,
                      decoration: const InputDecoration(
                        labelText: 'Search Name or Number',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No customer found.',
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (
                                BuildContext context,
                                int index,
                              ) {
                                final Customer customer =
                                    filtered[index];

                                return ListTile(
                                  title: Text(customer.name),
                                  subtitle:
                                      Text(customer.phone),
                                  onTap: () {
                                    _selectCustomer(customer);
                                    Navigator.of(dialogContext)
                                        .pop();
                                  },
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        await _createCustomer();
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create Customer'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    searchController.dispose();
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _customerNameController.text = customer.name;
      _customerNumberController.text = customer.phone;
    });
  }

  Future<void> _createCustomer() async {
    final Customer? customer =
        await showDialog<Customer>(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController =
            TextEditingController();
        final TextEditingController phoneController =
            TextEditingController();

        return AlertDialog(
          title: const Text('Create Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Customer Name *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Customer Number *',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name =
                    nameController.text.trim();
                final String phone =
                    phoneController.text.trim();

                if (name.isEmpty ||
                    !RegExp(r'^\d{10}$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a customer name and valid 10-digit number.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  final int id =
                      await _customerRepository.addCustomer(
                    Customer(
                      name: name,
                      phone: phone,
                    ),
                  );

                  final Customer created =
                      Customer(
                    id: id,
                    name: name,
                    phone: phone,
                  );

                  if (context.mounted) {
                    Navigator.of(context).pop(created);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to create customer.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Customer'),
            ),
          ],
        );
      },
    );

    if (customer == null || !mounted) return;

    _selectCustomer(customer);
  }

  String? _validateNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }

    final double? number =
        double.tryParse(value.trim());

    if (number == null || number <= 0) {
      return 'Enter a valid $label';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Name is required.'),
        ),
      );
      return;
    }

    if (!_isEditMode &&
        _customerNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Number is required.'),
        ),
      );
      return;
    }

    for (final _AccessoryItemController item in _items) {
      if (item.item == null || item.item!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select an Item for every row.'),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditMode) {
        final Accessory original = widget.accessory!;

        final _AccessoryItemController row = _items.first;

        final Accessory updated = Accessory(
          id: original.id,
          date: _selectedDate,
          customerName:
              _customerNameController.text.trim(),
          customerNumber:
              _customerNumberController.text.trim(),
          item: row.item!,
          quantity:
              _parseNumber(row.quantityController.text),
          rate: _parseNumber(row.rateController.text),
          totalAmount: _getItemTotal(row),
          paymentMethod: _paymentMethod,
          remarks: _remarksController.text.trim(),
        );

        await _accessoryRepository.updateAccessory(
          updated,
        );
      } else {
        for (final _AccessoryItemController row in _items) {
          final Accessory accessory = Accessory(
            date: _selectedDate,
            customerName:
                _customerNameController.text.trim(),
            customerNumber:
                _customerNumberController.text.trim(),
            item: row.item!,
            quantity:
                _parseNumber(row.quantityController.text),
            rate:
                _parseNumber(row.rateController.text),
            totalAmount: _getItemTotal(row),
            paymentMethod: _paymentMethod,
            remarks: _remarksController.text.trim(),
          );

          await _accessoryRepository.addAccessory(
            accessory,
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save Accessories: $e',
          ),
        ),
      );

      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildCustomerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _customerNumberController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              maxLength: 10,
              decoration: InputDecoration(
                labelText: 'Customer Number *',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: IconButton(
                  tooltip: 'Select Customer',
                  onPressed: _showCustomerPicker,
                  icon: const Icon(Icons.search),
                ),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Customer Number is required';
                }

                if (!RegExp(r'^\d{10}$')
                    .hasMatch(value.trim())) {
                  return 'Enter a valid 10-digit number';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _customerNameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Customer Name *',
                prefixIcon: const Icon(Icons.person),
                suffixIcon: IconButton(
                  tooltip: 'Select Customer',
                  onPressed: _showCustomerPicker,
                  icon: const Icon(Icons.search),
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Customer Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _createCustomer,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Create Customer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    _AccessoryItemController item,
    int index,
  ) {
    final double total = _getItemTotal(item);

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Item ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    tooltip: 'Remove Item',
                    onPressed: () =>
                        _removeItem(index),
                    icon: const Icon(
                      Icons.remove_circle_outline,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: item.item,
              decoration: const InputDecoration(
                labelText: 'Item *',
                prefixIcon: Icon(
                  Icons.shopping_bag_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: _itemOptions
                  .map(
                    (String value) =>
                        DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  item.item = value;
                });
              },
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Select an Item';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.quantityController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        _validateNumber(
                      value,
                      'Quantity',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: item.rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Rate *',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (String? value) =>
                        _validateNumber(
                      value,
                      'Rate',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_outlined,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                labelText: 'Date *',
                prefixIcon: Icon(
                  Icons.calendar_today_outlined,
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method *',
                prefixIcon: Icon(
                  Icons.payments_outlined,
                ),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Cash',
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: 'G Pay',
                  child: Text('G Pay'),
                ),
              ],
              onChanged: (String? value) {
                if (value == null) return;

                setState(() {
                  _paymentMethod = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                prefixIcon: Icon(
                  Icons.notes_outlined,
                ),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _isEditMode
        ? 'Edit Accessory'
        : widget.isDuplicate
            ? 'Duplicate Accessory'
            : 'Add Accessories';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            12,
            12,
            12,
            100,
          ),
          child: Column(
            children: [
              _buildCustomerSection(),
              const SizedBox(height: 12),
              _buildCommonSection(),
              const SizedBox(height: 12),
              ...List<Widget>.generate(
                _items.length,
                (int index) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildItemCard(
                    _items[index],
                    index,
                  ),
                ),
              ),
              if (!_isEditMode)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Add Another Item',
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Grand Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      Text(
                        '₹${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
