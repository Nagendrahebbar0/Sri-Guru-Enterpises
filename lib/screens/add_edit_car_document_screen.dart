// ============================================================
// FILE: add_edit_car_document_screen.dart
//
// PURPOSE:
// Provides the Add, Edit and Duplicate Car Document form.
//
// FUNCTIONALITY:
// - Adds a Car Document.
// - Edits a Car Document.
// - Duplicates a Car Document.
// - Selects Document Type.
// - Supports Other State Permit.
// - Shows Other State Name only when required.
// - Selects Date.
// - Selects Expiry Date.
// - Selects existing Customer.
// - Searches Customer by Name or Customer Number.
// - Creates a new Customer without leaving the workflow.
// - Automatically fills Customer Name and Customer Number.
// - Calculates Profit automatically.
//
// PROFIT:
// Profit = Income - Expense
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/car_document.dart';
import '../models/customer.dart';
import '../repositories/car_document_repository.dart';
import '../repositories/customer_repository.dart';
import 'add_edit_customer_screen.dart';

// ============================================================
// ADD / EDIT CAR DOCUMENT SCREEN
// ============================================================

class AddEditCarDocumentScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // EXISTING CAR DOCUMENT
  //
  // null = Add mode.
  // non-null = Edit mode.
  // ------------------------------------------------------------

  final CarDocument? carDocument;

  // ------------------------------------------------------------
  // DUPLICATE MODE
  //
  // true = create a NEW record.
  // false = normal Add/Edit.
  // ------------------------------------------------------------

  final bool isDuplicate;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const AddEditCarDocumentScreen({
    super.key,
    this.carDocument,
    this.isDuplicate = false,
  });

  @override
  State<AddEditCarDocumentScreen> createState() =>
      _AddEditCarDocumentScreenState();
}

// ============================================================
// STATE
// ============================================================

class _AddEditCarDocumentScreenState
    extends State<AddEditCarDocumentScreen> {
  // ------------------------------------------------------------
  // FORM KEY
  // ------------------------------------------------------------

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ------------------------------------------------------------
  // REPOSITORIES
  // ------------------------------------------------------------

  final CarDocumentRepository _repository =
  CarDocumentRepository();

  final CustomerRepository _customerRepository =
  CustomerRepository();

  // ------------------------------------------------------------
  // TEXT CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController _otherStateNameController =
  TextEditingController();

  final TextEditingController _customerNumberController =
  TextEditingController();

  final TextEditingController _customerNameController =
  TextEditingController();

  final TextEditingController _vehicleNumberController =
  TextEditingController();

  final TextEditingController _incomeController =
  TextEditingController();

  final TextEditingController _bbtduIdController =
  TextEditingController();

  final TextEditingController _expenseController =
  TextEditingController();

  final TextEditingController _profitController =
  TextEditingController();

  // ------------------------------------------------------------
  // DATES
  // ------------------------------------------------------------

  late DateTime _selectedDate;
  late DateTime _selectedExpiryDate;

  // ------------------------------------------------------------
  // DROPDOWNS
  // ------------------------------------------------------------

  String? _selectedDocumentType;
  String? _selectedPaymentMethod;

  // ------------------------------------------------------------
  // LOADING STATE
  // ------------------------------------------------------------

  bool _isSaving = false;

  // ============================================================
  // DOCUMENT TYPES
  // ============================================================

  static const List<String> _documentTypes = [
    'Insurance',
    'Road Tax',
    'Kerala Permit',
    'Tamil Nadu Permit',
    'Andhra Pradesh Permit',
    'Other State Permit',
  ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeForm();

    // Calculate profit whenever Income or Expense changes.
    _incomeController.addListener(_calculateProfit);
    _expenseController.addListener(_calculateProfit);
  }

  // ============================================================
  // INITIALIZE FORM
  // ============================================================

  void _initializeForm() {
    final CarDocument? existing =
        widget.carDocument;

    // ----------------------------------------------------------
    // DEFAULT DATE
    // ----------------------------------------------------------

    _selectedDate =
        existing?.date ?? DateTime.now();

    // ----------------------------------------------------------
    // DEFAULT EXPIRY DATE
    //
    // For a new document, default to one year from today.
    // ----------------------------------------------------------

    _selectedExpiryDate =
        existing?.expiryDate ??
            DateTime(
              _selectedDate.year + 1,
              _selectedDate.month,
              _selectedDate.day,
            );

    // ----------------------------------------------------------
    // EXISTING VALUES
    // ----------------------------------------------------------

    if (existing != null) {
      _selectedDocumentType =
          existing.documentType;

      _otherStateNameController.text =
          existing.otherStateName ?? '';

      _customerNumberController.text =
          existing.customerNumber;

      _customerNameController.text =
          existing.customerName;

      _vehicleNumberController.text =
          existing.vehicleNumber;

      _incomeController.text =
          existing.income.toString();

      _bbtduIdController.text =
          existing.bbtdUIdNo ?? '';

      _expenseController.text =
          existing.expense.toString();

      _profitController.text =
          existing.profit.toStringAsFixed(2);

      _selectedPaymentMethod =
          existing.paymentMethod;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _otherStateNameController.dispose();
    _customerNumberController.dispose();
    _customerNameController.dispose();
    _vehicleNumberController.dispose();
    _incomeController.dispose();
    _bbtduIdController.dispose();
    _expenseController.dispose();
    _profitController.dispose();

    super.dispose();
  }

  // ============================================================
  // CALCULATE PROFIT
  //
  // Profit = Income - Expense
  // ============================================================

  void _calculateProfit() {
    final double income =
        double.tryParse(
          _incomeController.text.trim(),
        ) ??
            0;

    final double expense =
        double.tryParse(
          _expenseController.text.trim(),
        ) ??
            0;

    final double profit =
    CarDocument.calculateProfit(
      income: income,
      expense: expense,
    );

    _profitController.value =
        TextEditingValue(
          text: profit.toStringAsFixed(2),
          selection: TextSelection.collapsed(
            offset: profit
                .toStringAsFixed(2)
                .length,
          ),
        );
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  Future<void> _selectDate() async {
    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  // ============================================================
  // SELECT EXPIRY DATE
  // ============================================================

  Future<void> _selectExpiryDate() async {
    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: _selectedExpiryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedExpiryDate = pickedDate;
    });
  }

  // ============================================================
  // SELECT CUSTOMER
  //
  // Loads customers from Customer Management.
  //
  // Search supports:
  // - Customer Name
  // - Customer Number
  //
  // The selected customer fills both fields.
  // ============================================================

  Future<void> _selectCustomer() async {
    final List<Customer> customers =
    await _customerRepository.getCustomers();

    if (!mounted) {
      return;
    }

    final Customer? selectedCustomer =
    await showDialog<Customer>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _CustomerSelectionDialog(
          customers: customers,
        );
      },
    );

    if (!mounted ||
        selectedCustomer == null) {
      return;
    }

    setState(() {
      _customerNameController.text =
          selectedCustomer.name;

      _customerNumberController.text =
          selectedCustomer.phone;
    });
  }

  // ============================================================
  // SAVE CAR DOCUMENT
  // ============================================================

  Future<void> _saveCarDocument() async {
    // ----------------------------------------------------------
    // VALIDATE FORM
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE DOCUMENT TYPE
    // ----------------------------------------------------------

    if (_selectedDocumentType == null) {
      _showError(
        'Please select document type.',
      );
      return;
    }

    // ----------------------------------------------------------
    // OTHER STATE NAME
    // ----------------------------------------------------------

    String? otherStateName;

    if (_selectedDocumentType ==
        'Other State Permit') {
      otherStateName =
          _otherStateNameController.text.trim();

      if (otherStateName.isEmpty) {
        _showError(
          'Please enter other state name.',
        );
        return;
      }
    }

    // ----------------------------------------------------------
    // PARSE INCOME
    // ----------------------------------------------------------

    final double? income =
    double.tryParse(
      _incomeController.text.trim(),
    );

    if (income == null ||
        income < 0) {
      _showError(
        'Please enter a valid income amount.',
      );
      return;
    }

    // ----------------------------------------------------------
    // PARSE EXPENSE
    // ----------------------------------------------------------

    final double? expense =
    double.tryParse(
      _expenseController.text.trim(),
    );

    if (expense == null ||
        expense < 0) {
      _showError(
        'Please enter a valid expense amount.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CALCULATE PROFIT
    // ----------------------------------------------------------

    final double profit =
    CarDocument.calculateProfit(
      income: income,
      expense: expense,
    );

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      final CarDocument carDocument =
      CarDocument(
        // ------------------------------------------------------
        // ID
        //
        // Duplicate mode creates a new record.
        // ------------------------------------------------------

        id: widget.isDuplicate
            ? null
            : widget.carDocument?.id,

        // ------------------------------------------------------
        // DOCUMENT TYPE
        // ------------------------------------------------------

        documentType:
        _selectedDocumentType!,

        // ------------------------------------------------------
        // OTHER STATE NAME
        // ------------------------------------------------------

        otherStateName:
        otherStateName,

        // ------------------------------------------------------
        // DATE
        // ------------------------------------------------------

        date: _selectedDate,

        // ------------------------------------------------------
        // EXPIRY DATE
        // ------------------------------------------------------

        expiryDate:
        _selectedExpiryDate,

        // ------------------------------------------------------
        // CUSTOMER NUMBER
        // ------------------------------------------------------

        customerNumber:
        _customerNumberController
            .text
            .trim(),

        // ------------------------------------------------------
        // CUSTOMER NAME
        // ------------------------------------------------------

        customerName:
        _customerNameController
            .text
            .trim(),

        // ------------------------------------------------------
        // VEHICLE NUMBER
        // ------------------------------------------------------

        vehicleNumber:
        _vehicleNumberController
            .text
            .trim(),

        // ------------------------------------------------------
        // INCOME
        // ------------------------------------------------------

        income: income,

        // ------------------------------------------------------
        // BBTDU ID
        //
        // Optional.
        // ------------------------------------------------------

        bbtdUIdNo:
        _bbtduIdController.text
            .trim()
            .isEmpty
            ? null
            : _bbtduIdController.text
            .trim(),

        // ------------------------------------------------------
        // EXPENSE
        // ------------------------------------------------------

        expense: expense,

        // ------------------------------------------------------
        // PROFIT
        //
        // Automatically calculated.
        // ------------------------------------------------------

        profit: profit,

        // ------------------------------------------------------
        // PAYMENT METHOD
        // ------------------------------------------------------

        paymentMethod:
        _selectedPaymentMethod!,
      );

      // --------------------------------------------------------
      // EDIT EXISTING RECORD
      // --------------------------------------------------------

      if (widget.carDocument != null &&
          !widget.isDuplicate) {
        await _repository.updateCarDocument(
          carDocument,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          'Car Document updated successfully.',
        );
      }

      // --------------------------------------------------------
      // ADD NEW RECORD
      //
      // Also handles Duplicate mode.
      // --------------------------------------------------------

      else {
        await _repository.addCarDocument(
          carDocument,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          widget.isDuplicate
              ? 'Car Document duplicated successfully.'
              : 'Car Document added successfully.',
        );
      }

      // --------------------------------------------------------
      // RETURN TO PREVIOUS SCREEN
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        'Unable to save Car Document.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccess(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final bool isEdit =
        widget.carDocument != null &&
            !widget.isDuplicate;

    final String screenTitle =
    widget.isDuplicate
        ? 'Duplicate Car Document'
        : isEdit
        ? 'Edit Car Document'
        : 'Add Car Document';

    return Scaffold(
      // ----------------------------------------------------------
      // APP BAR
      // ----------------------------------------------------------

      appBar: AppBar(
        title: Text(
          screenTitle,
        ),
      ),

      // ----------------------------------------------------------
      // BODY
      // ----------------------------------------------------------

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(16),
          child: Column(
            children: [
              // --------------------------------------------------
              // DOCUMENT TYPE
              // --------------------------------------------------

              _buildDocumentTypeDropdown(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // OTHER STATE NAME
              // --------------------------------------------------

              if (_selectedDocumentType ==
                  'Other State Permit') ...[
                _buildOtherStateNameField(),

                const SizedBox(
                  height: 16,
                ),
              ],

              // --------------------------------------------------
              // DATE
              // --------------------------------------------------

              _buildDateField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // EXPIRY DATE
              // --------------------------------------------------

              _buildExpiryDateField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // CUSTOMER
              // --------------------------------------------------

              _buildCustomerNameField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // CUSTOMER NUMBER
              // --------------------------------------------------

              _buildCustomerNumberField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // VEHICLE NUMBER
              // --------------------------------------------------

              _buildVehicleNumberField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // INCOME
              // --------------------------------------------------

              _buildIncomeField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // BBTDU ID
              // --------------------------------------------------

              _buildBbtduIdField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // EXPENSE
              // --------------------------------------------------

              _buildExpenseField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // PROFIT
              // --------------------------------------------------

              _buildProfitField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // PAYMENT METHOD
              // --------------------------------------------------

              _buildPaymentMethodDropdown(),

              const SizedBox(
                height: 24,
              ),

              // --------------------------------------------------
              // SAVE BUTTON
              // --------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving
                      ? null
                      : _saveCarDocument,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : 'Save Car Document',
                  ),
                ),
              ),

              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOCUMENT TYPE DROPDOWN
  // ============================================================

  Widget _buildDocumentTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedDocumentType,
      decoration:
      const InputDecoration(
        labelText: 'Document Type',
        prefixIcon: Icon(
          Icons.description_outlined,
        ),
      ),
      items: _documentTypes
          .map(
            (String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(type),
          );
        },
      )
          .toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedDocumentType = value;

          if (value !=
              'Other State Permit') {
            _otherStateNameController
                .clear();
          }
        });
      },
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select document type.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // OTHER STATE NAME
  // ============================================================

  Widget _buildOtherStateNameField() {
    return TextFormField(
      controller:
      _otherStateNameController,
      textCapitalization:
      TextCapitalization.words,
      decoration:
      const InputDecoration(
        labelText: 'Other State Name *',
        hintText: 'Example: Karnataka',
        prefixIcon: Icon(
          Icons.location_on_outlined,
        ),
      ),
      validator: (String? value) {
        if (_selectedDocumentType ==
            'Other State Permit') {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Please enter state name.';
          }
        }

        return null;
      },
    );
  }

  // ============================================================
  // DATE FIELD
  // ============================================================

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      controller:
      TextEditingController(
        text: DateFormat(
          'dd/MM/yyyy',
        ).format(
          _selectedDate,
        ),
      ),
      decoration:
      const InputDecoration(
        labelText: 'Date',
        prefixIcon: Icon(
          Icons.calendar_today_outlined,
        ),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
        ),
      ),
      onTap: _selectDate,
    );
  }

  // ============================================================
  // EXPIRY DATE FIELD
  // ============================================================

  Widget _buildExpiryDateField() {
    return TextFormField(
      readOnly: true,
      controller:
      TextEditingController(
        text: DateFormat(
          'dd/MM/yyyy',
        ).format(
          _selectedExpiryDate,
        ),
      ),
      decoration:
      const InputDecoration(
        labelText: 'Expiry Date',
        prefixIcon: Icon(
          Icons.event_available_outlined,
        ),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
        ),
      ),
      onTap: _selectExpiryDate,
      validator: (String? value) {
        if (!_selectedExpiryDate
            .isAfter(
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day - 1,
          ),
        )) {
          return 'Expiry date must be after document date.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CUSTOMER NAME
  // ============================================================

  Widget _buildCustomerNameField() {
    return TextFormField(
      controller:
      _customerNameController,
      readOnly: true,
      decoration:
      InputDecoration(
        labelText: 'Customer Name',
        hintText:
        'Select customer',
        prefixIcon: const Icon(
          Icons.person_outline,
        ),
        suffixIcon: IconButton(
          onPressed:
          _selectCustomer,
          icon: const Icon(
            Icons.search,
          ),
          tooltip:
          'Select Customer',
        ),
      ),
      onTap: _selectCustomer,
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select customer.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CUSTOMER NUMBER
  // ============================================================

  Widget _buildCustomerNumberField() {
    return TextFormField(
      controller:
      _customerNumberController,
      readOnly: true,
      keyboardType:
      TextInputType.phone,
      decoration:
      const InputDecoration(
        labelText: 'Customer Number',
        hintText:
        'Customer contact number',
        prefixIcon: Icon(
          Icons.phone_outlined,
        ),
      ),
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select customer.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // VEHICLE NUMBER
  // ============================================================

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller:
      _vehicleNumberController,
      textCapitalization:
      TextCapitalization.characters,
      decoration:
      const InputDecoration(
        labelText: 'Vehicle Number',
        hintText:
        'Example: KA03AP3691',
        prefixIcon: Icon(
          Icons.confirmation_number_outlined,
        ),
      ),
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter vehicle number.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // INCOME
  // ============================================================

  Widget _buildIncomeField() {
    return TextFormField(
      controller:
      _incomeController,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration:
      const InputDecoration(
        labelText: 'Income',
        hintText:
        'Example: 1000',
        prefixIcon: Icon(
          Icons.currency_rupee,
        ),
      ),
      validator: (String? value) {
        final String text =
            value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Please enter income.';
        }

        final double? amount =
        double.tryParse(text);

        if (amount == null ||
            amount < 0) {
          return 'Enter a valid income amount.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // BBTDU ID
  // ============================================================

  Widget _buildBbtduIdField() {
    return TextFormField(
      controller:
      _bbtduIdController,
      textCapitalization:
      TextCapitalization.characters,
      decoration:
      const InputDecoration(
        labelText:
        'BBTDU ID No. (Optional)',
        hintText:
        'Enter BBTDU ID if available',
        prefixIcon: Icon(
          Icons.badge_outlined,
        ),
      ),
    );
  }

  // ============================================================
  // EXPENSE
  // ============================================================

  Widget _buildExpenseField() {
    return TextFormField(
      controller:
      _expenseController,
      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration:
      const InputDecoration(
        labelText: 'Expense',
        hintText:
        'Example: 500',
        prefixIcon: Icon(
          Icons.money_off_outlined,
        ),
      ),
      validator: (String? value) {
        final String text =
            value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Please enter expense.';
        }

        final double? amount =
        double.tryParse(text);

        if (amount == null ||
            amount < 0) {
          return 'Enter a valid expense amount.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PROFIT
  //
  // READ ONLY
  //
  // Profit = Income - Expense
  // ============================================================

  Widget _buildProfitField() {
    return TextFormField(
      controller:
      _profitController,
      readOnly: true,
      decoration:
      const InputDecoration(
        labelText: 'Profit',
        prefixIcon: Icon(
          Icons.trending_up_outlined,
        ),
        helperText:
        'Automatically calculated: Income - Expense',
      ),
    );
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedPaymentMethod,
      decoration:
      const InputDecoration(
        labelText: 'Cash / G Pay',
        prefixIcon: Icon(
          Icons.payment_outlined,
        ),
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
        setState(() {
          _selectedPaymentMethod =
              value;
        });
      },
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select payment method.';
        }

        return null;
      },
    );
  }
}

// ============================================================
// CUSTOMER SELECTION DIALOG
//
// SEARCH:
// - Customer Name
// - Customer Number
//
// FEATURES:
// - Existing customer selection
// - Create Customer
// - Automatically returns newly created customer
// ============================================================

class _CustomerSelectionDialog
    extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectionDialog({
    required this.customers,
  });

  @override
  State<_CustomerSelectionDialog>
  createState() =>
      _CustomerSelectionDialogState();
}

// ============================================================
// CUSTOMER SELECTION DIALOG STATE
// ============================================================

class _CustomerSelectionDialogState
    extends State<
        _CustomerSelectionDialog> {
  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  // ------------------------------------------------------------

  final TextEditingController
  _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  // ------------------------------------------------------------

  final CustomerRepository
  _customerRepository =
  CustomerRepository();

  // ------------------------------------------------------------
  // FILTERED CUSTOMERS
  // ------------------------------------------------------------

  late List<Customer>
  _filteredCustomers;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _filteredCustomers =
    List<Customer>.from(
      widget.customers,
    );

    _searchController.addListener(
      _filterCustomers,
    );
  }

  // ============================================================
  // FILTER CUSTOMERS
  //
  // Search by:
  // - Name
  // - Customer Number
  // ============================================================

  void _filterCustomers() {
    final String search =
    _searchController.text
        .trim()
        .toLowerCase();

    setState(() {
      if (search.isEmpty) {
        _filteredCustomers =
        List<Customer>.from(
          widget.customers,
        );

        return;
      }

      _filteredCustomers =
          widget.customers
              .where(
                (Customer customer) {
              final String name =
              customer.name
                  .toLowerCase();

              final String phone =
              customer.phone
                  .toLowerCase();

              return name.contains(search) ||
                  phone.contains(search);
            },
          )
              .toList();
    });
  }

  // ============================================================
  // CREATE CUSTOMER
  //
  // Create Customer
  //       ↓
  // Save
  //       ↓
  // Return to Car Documents
  //       ↓
  // Automatically select new customer
  // ============================================================

  Future<void> _createCustomer() async {
    // ----------------------------------------------------------
    // REMEMBER CURRENT CUSTOMER IDs
    // ----------------------------------------------------------

    final Set<int>
    existingCustomerIds =
    widget.customers
        .where(
          (Customer customer) =>
      customer.id != null,
    )
        .map(
          (Customer customer) =>
      customer.id!,
    )
        .toSet();

    // ----------------------------------------------------------
    // OPEN ADD CUSTOMER SCREEN
    // ----------------------------------------------------------

    final bool? customerCreated =
    await Navigator.of(context)
        .push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (BuildContext context) {
          return const AddEditCustomerScreen();
        },
      ),
    );

    // ----------------------------------------------------------
    // CHECK RESULT
    // ----------------------------------------------------------

    if (!mounted ||
        customerCreated != true) {
      return;
    }

    // ----------------------------------------------------------
    // LOAD UPDATED CUSTOMER LIST
    // ----------------------------------------------------------

    final List<Customer>
    updatedCustomers =
    await _customerRepository
        .getCustomers();

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // FIND NEW CUSTOMER
    // ----------------------------------------------------------

    Customer? newCustomer;

    for (final Customer customer
    in updatedCustomers) {
      if (customer.id != null &&
          !existingCustomerIds
              .contains(customer.id)) {
        newCustomer = customer;
        break;
      }
    }

    // ----------------------------------------------------------
    // RETURN NEW CUSTOMER
    // ----------------------------------------------------------

    if (newCustomer != null) {
      Navigator.of(context).pop(
        newCustomer,
      );

      return;
    }

    // ----------------------------------------------------------
    // FALLBACK
    //
    // Refresh customer list instead of
    // selecting an unrelated customer.
    // ----------------------------------------------------------

    setState(() {
      _filteredCustomers =
      List<Customer>.from(
        updatedCustomers,
      );
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      title: const Text(
        'Select Customer',
      ),

      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            // --------------------------------------------------
            // SEARCH
            // --------------------------------------------------

            TextField(
              controller:
              _searchController,
              decoration:
              const InputDecoration(
                hintText:
                'Search name or customer number...',
                prefixIcon:
                Icon(Icons.search),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // --------------------------------------------------
            // CUSTOMER LIST
            // --------------------------------------------------

            Expanded(
              child:
              _filteredCustomers
                  .isEmpty
                  ? Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  const Icon(
                    Icons
                        .person_search_outlined,
                    size: 48,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'No customers found.',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  FilledButton.icon(
                    onPressed:
                    _createCustomer,
                    icon:
                    const Icon(
                      Icons
                          .person_add_outlined,
                    ),
                    label:
                    const Text(
                      'Create Customer',
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount:
                _filteredCustomers
                    .length,
                itemBuilder:
                    (
                    BuildContext context,
                    int index,
                    ) {
                  final Customer
                  customer =
                  _filteredCustomers[
                  index];

                  return ListTile(
                    leading:
                    const CircleAvatar(
                      child:
                      Icon(
                        Icons.person,
                      ),
                    ),

                    title:
                    Text(
                      customer.name,
                    ),

                    subtitle:
                    Text(
                      customer.phone,
                    ),

                    trailing:
                    const Icon(
                      Icons
                          .arrow_forward_ios,
                      size: 16,
                    ),

                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(
                        customer,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --------------------------------------------------------
      // ACTIONS
      // --------------------------------------------------------

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context)
                .pop();
          },
          child:
          const Text('Cancel'),
        ),

        TextButton.icon(
          onPressed:
          _createCustomer,
          icon: const Icon(
            Icons
                .person_add_outlined,
          ),
          label:
          const Text(
            'Create Customer',
          ),
        ),
      ],
    );
  }
}