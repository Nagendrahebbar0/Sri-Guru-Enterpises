// ============================================================
// FILE: add_edit_emission_test_screen.dart
//
// PURPOSE:
// Provides the Add, Edit and Duplicate Emission Test form
// for Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Adds a new Emission Test.
// - Edits an existing Emission Test.
// - Duplicates an existing Emission Test.
// - Selects service date.
// - Selects an existing customer by NAME.
// - Allows vehicle number.
// - Records income.
// - BBTDU ID No. is optional.
// - Selects Petrol / Diesel.
// - Selects Cash / G Pay.
//
// CUSTOMER CONNECTION:
//
// The Name field is connected to the existing Customer
// Management module.
//
// IMPORTANT:
// We only store the CUSTOMER NAME in the Emission record.
// We do NOT add customer ID or customer number.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/emission_test.dart';
import '../repositories/customer_repository.dart';
import '../repositories/emission_test_repository.dart';
import 'add_edit_customer_screen.dart';

// ============================================================
// ADD / EDIT EMISSION TEST SCREEN
// ============================================================

class AddEditEmissionTestScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // EXISTING EMISSION TEST
  //
  // null = Add mode.
  // non-null = Edit mode.
  // ------------------------------------------------------------

  final EmissionTest? emissionTest;

  // ------------------------------------------------------------
  // DUPLICATE MODE
  //
  // true = create a new record using existing information.
  // false = normal Add/Edit operation.
  // ------------------------------------------------------------

  final bool isDuplicate;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const AddEditEmissionTestScreen({
    super.key,
    this.emissionTest,
    this.isDuplicate = false,
  });

  @override
  State<AddEditEmissionTestScreen> createState() =>
      _AddEditEmissionTestScreenState();
}

// ============================================================
// STATE
// ============================================================

class _AddEditEmissionTestScreenState
    extends State<AddEditEmissionTestScreen> {
  // ------------------------------------------------------------
  // FORM KEY
  // ------------------------------------------------------------

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final EmissionTestRepository _repository =
  EmissionTestRepository();

  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  //
  // Used to load customers from Customer Management.
  // ------------------------------------------------------------

  final CustomerRepository _customerRepository =
  CustomerRepository();

  // ------------------------------------------------------------
  // TEXT CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _vehicleNumberController =
  TextEditingController();

  final TextEditingController _incomeController =
  TextEditingController();

  final TextEditingController _bbtduIdController =
  TextEditingController();

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  late DateTime _selectedDate;

  // ------------------------------------------------------------
  // FUEL TYPE
  // ------------------------------------------------------------

  String? _selectedFuelType;

  // ------------------------------------------------------------
  // PAYMENT METHOD
  // ------------------------------------------------------------

  String? _selectedPaymentMethod;

  // ------------------------------------------------------------
  // LOADING STATE
  // ------------------------------------------------------------

  bool _isSaving = false;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _initializeForm();
  }

  // ============================================================
  // INITIALIZE FORM
  // ============================================================

  void _initializeForm() {
    final EmissionTest? existing =
        widget.emissionTest;

    // ----------------------------------------------------------
    // DEFAULT DATE
    // ----------------------------------------------------------

    _selectedDate =
        existing?.date ?? DateTime.now();

    // ----------------------------------------------------------
    // EXISTING VALUES
    // ----------------------------------------------------------

    if (existing != null) {
      _nameController.text =
          existing.name;

      _vehicleNumberController.text =
          existing.vehicleNumber ?? '';

      _incomeController.text =
          existing.income.toString();

      _bbtduIdController.text =
          existing.bbtdUIdNo ?? '';

      _selectedFuelType =
          existing.fuelType;

      _selectedPaymentMethod =
          existing.paymentMethod;
    }
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
  // SELECT CUSTOMER
  //
  // Loads customers from Customer Management and allows the
  // user to select a customer by name.
  //
  // ONLY THE CUSTOMER NAME IS USED.
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
      _nameController.text =
          selectedCustomer.name;
    });
  }

  // ============================================================
  // SAVE EMISSION TEST
  // ============================================================

  Future<void> _saveEmissionTest() async {
    // ----------------------------------------------------------
    // VALIDATE FORM
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
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
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE EMISSION TEST OBJECT
      // --------------------------------------------------------

      final EmissionTest emissionTest =
      EmissionTest(
        // ------------------------------------------------------
        // ID
        //
        // Duplicate mode creates a new record.
        // ------------------------------------------------------

        id: widget.isDuplicate
            ? null
            : widget.emissionTest?.id,

        // ------------------------------------------------------
        // DATE
        // ------------------------------------------------------

        date: _selectedDate,

        // ------------------------------------------------------
        // CUSTOMER NAME
        // ------------------------------------------------------

        name:
        _nameController.text.trim(),

        // ------------------------------------------------------
        // VEHICLE NUMBER
        // ------------------------------------------------------

        vehicleNumber:
        _vehicleNumberController.text.trim(),

        // ------------------------------------------------------
        // INCOME
        // ------------------------------------------------------

        income: income,

        // ------------------------------------------------------
        // BBTDU ID
        //
        // Optional.
        //
        // Empty text is stored as null.
        // ------------------------------------------------------

        bbtdUIdNo:
        _bbtduIdController.text
            .trim()
            .isEmpty
            ? null
            : _bbtduIdController.text.trim(),

        // ------------------------------------------------------
        // FUEL TYPE
        // ------------------------------------------------------

        fuelType:
        _selectedFuelType!,

        // ------------------------------------------------------
        // PAYMENT METHOD
        // ------------------------------------------------------

        paymentMethod:
        _selectedPaymentMethod!,
      );

      // --------------------------------------------------------
      // EDIT EXISTING RECORD
      // --------------------------------------------------------

      if (widget.emissionTest != null &&
          !widget.isDuplicate) {
        await _repository.updateEmissionTest(
          emissionTest,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          'Emission Test updated successfully.',
        );
      }

      // --------------------------------------------------------
      // ADD NEW RECORD
      //
      // This also handles Duplicate mode.
      // --------------------------------------------------------

      else {
        await _repository.addEmissionTest(
          emissionTest,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          widget.isDuplicate
              ? 'Emission Test duplicated successfully.'
              : 'Emission Test added successfully.',
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
        'Unable to save Emission Test.',
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
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
    final bool isEdit =
        widget.emissionTest != null &&
            !widget.isDuplicate;

    final String screenTitle =
    widget.isDuplicate
        ? 'Duplicate Emission Test'
        : isEdit
        ? 'Edit Emission Test'
        : 'Add Emission Test';

    return Scaffold(
      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        title: Text(
          screenTitle,
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // --------------------------------------------------
              // DATE
              // --------------------------------------------------

              _buildDateField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // CUSTOMER NAME
              // --------------------------------------------------

              _buildNameField(),

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
              //
              // OPTIONAL
              // --------------------------------------------------

              _buildBbtduIdField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // FUEL TYPE
              // --------------------------------------------------

              _buildFuelTypeDropdown(),

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
                  onPressed:
                  _isSaving
                      ? null
                      : _saveEmissionTest,
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
                        : 'Save Emission Test',
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
  // DATE FIELD
  // ============================================================

  Widget _buildDateField() {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(
        text: DateFormat(
          'dd/MM/yyyy',
        ).format(
          _selectedDate,
        ),
      ),
      decoration: const InputDecoration(
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
  // CUSTOMER NAME
  //
  // Customer is selected from Customer Management.
  // ============================================================

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,

      readOnly: true,

      decoration: InputDecoration(
        labelText: 'Name',
        hintText: 'Select customer',
        prefixIcon: const Icon(
          Icons.person_outline,
        ),
        suffixIcon: IconButton(
          onPressed: _selectCustomer,
          icon: const Icon(
            Icons.search,
          ),
          tooltip: 'Select Customer',
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
  // VEHICLE NUMBER
  // ============================================================

  Widget _buildVehicleNumberField() {
    return TextFormField(
      controller:
      _vehicleNumberController,

      textCapitalization:
      TextCapitalization.characters,

      decoration: const InputDecoration(
        labelText: 'Vehicle Number',
        hintText: 'Example: KA03AP3691',
        prefixIcon: Icon(
          Icons.confirmation_number_outlined,
        ),
      ),

      validator: (String? value) {
        // ------------------------------------------------------
        // VEHICLE NUMBER IS OPTIONAL
        // ------------------------------------------------------

        return null;
      },
    );
  }

  // ============================================================
  // INCOME
  // ============================================================

  Widget _buildIncomeField() {
    return TextFormField(
      controller: _incomeController,

      keyboardType:
      const TextInputType.numberWithOptions(
        decimal: true,
      ),

      decoration: const InputDecoration(
        labelText: 'Income',
        hintText: 'Example: 160',
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
  //
  // OPTIONAL
  // ============================================================

  Widget _buildBbtduIdField() {
    return TextFormField(
      controller:
      _bbtduIdController,

      textCapitalization:
      TextCapitalization.characters,

      decoration: const InputDecoration(
        labelText: 'BBTDU ID No. (Optional)',
        hintText: 'Enter BBTDU ID if available',
        prefixIcon: Icon(
          Icons.badge_outlined,
        ),
      ),

      // --------------------------------------------------------
      // NO VALIDATOR
      //
      // BBTDU ID is optional.
      // --------------------------------------------------------

      validator: (String? value) {
        return null;
      },
    );
  }

  // ============================================================
  // FUEL TYPE
  // ============================================================

  Widget _buildFuelTypeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedFuelType,

      decoration: const InputDecoration(
        labelText: 'Fuel Type',
        prefixIcon: Icon(
          Icons.local_gas_station_outlined,
        ),
      ),

      items: const [
        DropdownMenuItem(
          value: 'Petrol',
          child: Text(
            'Petrol',
          ),
        ),
        DropdownMenuItem(
          value: 'Diesel',
          child: Text(
            'Diesel',
          ),
        ),
      ],

      onChanged: (String? value) {
        setState(() {
          _selectedFuelType = value;
        });
      },

      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select fuel type.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // PAYMENT METHOD
  // ============================================================

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      initialValue:
      _selectedPaymentMethod,

      decoration: const InputDecoration(
        labelText: 'Payment Method',
        prefixIcon: Icon(
          Icons.payment_outlined,
        ),
      ),

      items: const [
        DropdownMenuItem(
          value: 'Cash',
          child: Text(
            'Cash',
          ),
        ),
        DropdownMenuItem(
          value: 'G Pay',
          child: Text(
            'G Pay',
          ),
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();

    _vehicleNumberController.dispose();

    _incomeController.dispose();

    _bbtduIdController.dispose();

    super.dispose();
  }
}

// ============================================================
// CUSTOMER SELECTION DIALOG
//
// Displays customers from Customer Management.
//
// SEARCH:
// - Customer Name
// - Customer Number
//
// IMPORTANT:
// The selected customer's NAME is returned to the Emission
// form. No customer ID or customer number is stored.
// ============================================================

class _CustomerSelectionDialog extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectionDialog({
    required this.customers,
  });

  @override
  State<_CustomerSelectionDialog> createState() =>
      _CustomerSelectionDialogState();
}

// ============================================================
// CUSTOMER SELECTION DIALOG STATE
// ============================================================

class _CustomerSelectionDialogState
    extends State<_CustomerSelectionDialog> {
  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  // ------------------------------------------------------------

  final CustomerRepository _customerRepository =
  CustomerRepository();

  // ------------------------------------------------------------
  // FILTERED CUSTOMERS
  // ------------------------------------------------------------

  late List<Customer> _filteredCustomers;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _filteredCustomers =
    List<Customer>.from(widget.customers);

    _searchController.addListener(
      _filterCustomers,
    );
  }

  // ============================================================
  // FILTER CUSTOMERS
  //
  // Emission customer lookup uses CUSTOMER NAME only.
  //
  // Customer Number is intentionally not used here.
  // ============================================================

  void _filterCustomers() {
    final String search =
    _searchController.text.trim().toLowerCase();

    setState(() {
      if (search.isEmpty) {
        _filteredCustomers =
        List<Customer>.from(widget.customers);
        return;
      }

      _filteredCustomers = widget.customers
          .where(
            (Customer customer) =>
            customer.name.toLowerCase().contains(search),
      )
          .toList();
    });
  }

  // ============================================================
  // CREATE CUSTOMER
  //
  // Opens Customer Management.
  //
  // After saving:
  //
  // Create Customer
  //       ↓
  // Save
  //       ↓
  // Return to Emission
  //       ↓
  // Automatically select new customer
  // ============================================================

  Future<void> _createCustomer() async {
    // ----------------------------------------------------------
    // REMEMBER EXISTING CUSTOMER IDs
    //
    // This allows us to identify the customer created during
    // this operation without adding Customer ID to the
    // Emission Test model.
    // ----------------------------------------------------------

    final Set<int> existingCustomerIds = widget.customers
        .where((Customer customer) => customer.id != null)
        .map((Customer customer) => customer.id!)
        .toSet();

    // ----------------------------------------------------------
    // OPEN ADD CUSTOMER SCREEN
    // ----------------------------------------------------------

    final bool? customerCreated =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return const AddEditCustomerScreen();
        },
      ),
    );

    if (!mounted || customerCreated != true) {
      return;
    }

    // ----------------------------------------------------------
    // LOAD UPDATED CUSTOMER LIST
    // ----------------------------------------------------------

    final List<Customer> updatedCustomers =
    await _customerRepository.getCustomers();

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // FIND NEWLY CREATED CUSTOMER
    // ----------------------------------------------------------

    Customer? newCustomer;

    for (final Customer customer in updatedCustomers) {
      if (customer.id != null &&
          !existingCustomerIds.contains(customer.id)) {
        newCustomer = customer;
        break;
      }
    }

    // ----------------------------------------------------------
    // RETURN NEW CUSTOMER TO EMISSION FORM
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
    // If the newly created record cannot be identified, refresh
    // the dialog instead of selecting an unrelated customer.
    // ----------------------------------------------------------

    setState(() {
      _filteredCustomers =
      List<Customer>.from(updatedCustomers);
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Select Customer',
      ),

      content: SizedBox(
        width: double.maxFinite,
        height: 450,

        child: Column(
          children: [
            // ==================================================
            // SEARCH
            // ==================================================

            TextField(
              controller: _searchController,

              decoration: const InputDecoration(
                hintText: 'Search customer name...',
                prefixIcon: Icon(
                  Icons.search,
                ),
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // CUSTOMER LIST
            // ==================================================

            Expanded(
              child: _filteredCustomers.isEmpty
                  ? Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_search_outlined,
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
                    onPressed: _createCustomer,
                    icon: const Icon(
                      Icons.person_add_outlined,
                    ),
                    label: const Text(
                      'Create Customer',
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                itemCount:
                _filteredCustomers.length,

                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  final Customer customer =
                  _filteredCustomers[index];

                  return ListTile(
                    leading:
                    const CircleAvatar(
                      child: Icon(
                        Icons.person,
                      ),
                    ),

                    // ------------------------------------------------
                    // EMISSION USES CUSTOMER NAME ONLY
                    // ------------------------------------------------

                    title: Text(
                      customer.name,
                    ),

                    trailing:
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),

                    onTap: () {
                      Navigator.of(context).pop(
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

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
          ),
        ),

        TextButton.icon(
          onPressed: _createCustomer,
          icon: const Icon(
            Icons.person_add_outlined,
          ),
          label: const Text(
            'Create Customer',
          ),
        ),
      ],
    );
  }
}
