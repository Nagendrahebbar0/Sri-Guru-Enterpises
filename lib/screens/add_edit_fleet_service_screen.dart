// ============================================================
// FILE: add_edit_fleet_service_screen.dart
//
// PURPOSE:
// Provides the Add, Edit and Duplicate Fleet Service form
// for Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Adds a new Fleet Service.
// - Edits an existing Fleet Service.
// - Duplicates an existing Fleet Service.
// - Provides Toyota vehicle type options.
// - Provides Maruti Suzuki vehicle type options.
// - Allows a custom vehicle type.
// - Selects service date.
// - Validates required fields.
// - Automatically calculates the next Total Count.
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/fleet_service.dart';
import '../repositories/fleet_service_repository.dart';
import 'add_edit_customer_screen.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
// ============================================================
// ADD / EDIT FLEET SERVICE SCREEN
// ============================================================

class AddEditFleetServiceScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // EXISTING FLEET SERVICE
  //
  // null = Add mode.
  // non-null = Edit mode.
  // ------------------------------------------------------------

  final FleetService? fleetService;

  // ------------------------------------------------------------
  // DUPLICATE MODE
  //
  // true = create a NEW record using existing information.
  //
  // false = normal Add/Edit operation.
  // ------------------------------------------------------------

  final bool isDuplicate;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const AddEditFleetServiceScreen({
    super.key,
    this.fleetService,
    this.isDuplicate = false,
  });

  @override
  State<AddEditFleetServiceScreen> createState() =>
      _AddEditFleetServiceScreenState();
}

// ============================================================
// STATE
// ============================================================

class _AddEditFleetServiceScreenState
    extends State<AddEditFleetServiceScreen> {
  // ------------------------------------------------------------
  // FORM KEY
  // ------------------------------------------------------------

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final FleetServiceRepository _repository =
  FleetServiceRepository();
  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  //
  // Used to load customers from the existing Customer Management
  // database.
  // ------------------------------------------------------------

  final CustomerRepository _customerRepository =
  CustomerRepository();
  // ------------------------------------------------------------
  // TEXT CONTROLLERS
  // ------------------------------------------------------------

  final TextEditingController _vehicleNumberController =
  TextEditingController();

  final TextEditingController _customerNumberController =
  TextEditingController();

  final TextEditingController _odometerController =
  TextEditingController();

  final TextEditingController _workDoneController =
  TextEditingController();

  final TextEditingController _customVehicleTypeController =
  TextEditingController();

  // ------------------------------------------------------------
  // DATE
  // ------------------------------------------------------------

  late DateTime _selectedDate;

  // ------------------------------------------------------------
  // VEHICLE BRAND
  // ------------------------------------------------------------

  String? _selectedVehicleBrand;

  // ------------------------------------------------------------
  // VEHICLE TYPE
  // ------------------------------------------------------------

  String? _selectedVehicleType;

  // ------------------------------------------------------------
  // LOADING STATE
  // ------------------------------------------------------------

  bool _isSaving = false;

  // ------------------------------------------------------------
  // NEXT TOTAL COUNT
  // ------------------------------------------------------------

  int _nextTotalCount = 1;

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

  Future<void> _initializeForm() async {
    final FleetService? existing =
        widget.fleetService;

    // ----------------------------------------------------------
    // DEFAULT DATE
    // ----------------------------------------------------------

    _selectedDate =
        existing?.date ?? DateTime.now();

    // ----------------------------------------------------------
    // EXISTING VEHICLE BRAND
    // ----------------------------------------------------------

    _selectedVehicleBrand =
        existing?.vehicleBrand;

    // ----------------------------------------------------------
    // EXISTING VEHICLE TYPE
    // ----------------------------------------------------------

    _selectedVehicleType =
        existing?.vehicleType;

    // ----------------------------------------------------------
    // EXISTING TEXT VALUES
    // ----------------------------------------------------------

    if (existing != null) {
      _vehicleNumberController.text =
          existing.vehicleNumber;

      _customerNumberController.text =
          existing.customerNumber;

      _odometerController.text =
          existing.odometer.toString();

      _workDoneController.text =
          existing.workDone;

      // --------------------------------------------------------
      // CHECK WHETHER VEHICLE TYPE IS CUSTOM
      // --------------------------------------------------------

      if (_isCustomVehicleType(
        existing.vehicleBrand,
        existing.vehicleType,
      )) {
        _selectedVehicleType = 'Other';

        _customVehicleTypeController.text =
            existing.vehicleType;
      }
    }

    // ----------------------------------------------------------
    // CALCULATE NEXT TOTAL COUNT
    // ----------------------------------------------------------

    await _calculateNextTotalCount();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // CALCULATE NEXT TOTAL COUNT
  // ============================================================

  Future<void> _calculateNextTotalCount() async {
    try {
      final List<FleetService> services =
      await _repository.getFleetServices();

      if (services.isEmpty) {
        _nextTotalCount = 1;
        return;
      }

      int maximumCount = 0;

      for (final FleetService service in services) {
        if (service.totalCount > maximumCount) {
          maximumCount = service.totalCount;
        }
      }

      // --------------------------------------------------------
      // EDIT MODE
      //
      // Preserve the existing count.
      // --------------------------------------------------------

      if (widget.fleetService != null &&
          !widget.isDuplicate) {
        _nextTotalCount =
            widget.fleetService!.totalCount;
      } else {
        _nextTotalCount =
            maximumCount + 1;
      }
    } catch (_) {
      _nextTotalCount = 1;
    }
  }

  // ============================================================
  // TOYOTA VEHICLE TYPES
  // ============================================================

  static const List<String> _toyotaVehicleTypes = [
    'Etios',
    'Innova',
    'Innova Crysta',
    'Rumion',
    'Other',
  ];

  // ============================================================
  // MARUTI SUZUKI VEHICLE TYPES
  // ============================================================

  static const List<String> _marutiVehicleTypes = [
    'Dzire',
    'Swift',
    'Ertiga',
    'Tours',
    'Other',
  ];

  // ============================================================
  // GET VEHICLE TYPES
  // ============================================================

  List<String> _getVehicleTypes() {
    if (_selectedVehicleBrand == 'Toyota') {
      return _toyotaVehicleTypes;
    }

    if (_selectedVehicleBrand == 'Maruti Suzuki') {
      return _marutiVehicleTypes;
    }

    return [];
  }

  // ============================================================
  // CHECK CUSTOM VEHICLE TYPE
  // ============================================================

  bool _isCustomVehicleType(
      String brand,
      String vehicleType,
      ) {
    if (brand == 'Toyota') {
      return !_toyotaVehicleTypes
          .where((String type) => type != 'Other')
          .contains(vehicleType);
    }

    if (brand == 'Maruti Suzuki') {
      return !_marutiVehicleTypes
          .where((String type) => type != 'Other')
          .contains(vehicleType);
    }

    return true;
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
  // SAVE FLEET SERVICE
  // ============================================================

  Future<void> _saveFleetService() async {
    // ----------------------------------------------------------
    // VALIDATE FORM
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE BRAND
    // ----------------------------------------------------------

    if (_selectedVehicleBrand == null) {
      _showError(
        'Please select the vehicle brand.',
      );
      return;
    }

    // ----------------------------------------------------------
    // VALIDATE VEHICLE TYPE
    // ----------------------------------------------------------

    if (_selectedVehicleType == null) {
      _showError(
        'Please select the vehicle type.',
      );
      return;
    }

    // ----------------------------------------------------------
    // DETERMINE ACTUAL VEHICLE TYPE
    // ----------------------------------------------------------

    String actualVehicleType =
    _selectedVehicleType!;

    if (_selectedVehicleType == 'Other') {
      actualVehicleType =
          _customVehicleTypeController.text.trim();

      if (actualVehicleType.isEmpty) {
        _showError(
          'Please enter the vehicle type.',
        );
        return;
      }
    }

    // ----------------------------------------------------------
    // PARSE ODOMETER
    // ----------------------------------------------------------

    final int? odometer =
    int.tryParse(
      _odometerController.text.trim(),
    );

    if (odometer == null) {
      _showError(
        'Please enter a valid odometer reading.',
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
      // CREATE FLEET SERVICE OBJECT
      // --------------------------------------------------------

      final FleetService service =
      FleetService(
        // ------------------------------------------------------
        // ID
        //
        // In duplicate mode we intentionally don't preserve
        // the old ID.
        // ------------------------------------------------------

        id: widget.isDuplicate
            ? null
            : widget.fleetService?.id,

        // ------------------------------------------------------
        // DATE
        // ------------------------------------------------------

        date: _selectedDate,

        // ------------------------------------------------------
        // VEHICLE BRAND
        // ------------------------------------------------------

        vehicleBrand:
        _selectedVehicleBrand!,

        // ------------------------------------------------------
        // VEHICLE TYPE
        // ------------------------------------------------------

        vehicleType:
        actualVehicleType,

        // ------------------------------------------------------
        // VEHICLE NUMBER
        // ------------------------------------------------------

        vehicleNumber:
        _vehicleNumberController.text.trim(),

        // ------------------------------------------------------
        // CUSTOMER NUMBER
        // ------------------------------------------------------

        customerNumber:
        _customerNumberController.text.trim(),

        // ------------------------------------------------------
        // ODOMETER
        // ------------------------------------------------------

        odometer: odometer,

        // ------------------------------------------------------
        // WORK DONE
        // ------------------------------------------------------

        workDone:
        _workDoneController.text.trim(),

        // ------------------------------------------------------
        // TOTAL COUNT
        // ------------------------------------------------------

        totalCount:
        _nextTotalCount,
      );

      // --------------------------------------------------------
      // EDIT EXISTING RECORD
      // --------------------------------------------------------

      if (widget.fleetService != null &&
          !widget.isDuplicate) {
        await _repository.updateFleetService(
          service,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          'Fleet Service updated successfully.',
        );
      }

      // --------------------------------------------------------
      // ADD NEW RECORD
      //
      // This also handles Duplicate mode.
      // --------------------------------------------------------

      else {
        await _repository.addFleetService(
          service,
        );

        if (!mounted) {
          return;
        }

        _showSuccess(
          widget.isDuplicate
              ? 'Fleet Service duplicated successfully.'
              : 'Fleet Service added successfully.',
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
        'Unable to save Fleet Service.',
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
    ScaffoldMessenger.of(context).showSnackBar(
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
        widget.fleetService != null &&
            !widget.isDuplicate;

    final String screenTitle =
    widget.isDuplicate
        ? 'Duplicate Fleet Service'
        : isEdit
        ? 'Edit Fleet Service'
        : 'Add Fleet Service';

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
              // VEHICLE BRAND
              // --------------------------------------------------

              _buildVehicleBrandDropdown(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // VEHICLE TYPE
              // --------------------------------------------------

              _buildVehicleTypeDropdown(),

              // --------------------------------------------------
              // CUSTOM VEHICLE TYPE
              // --------------------------------------------------

              if (_selectedVehicleType == 'Other') ...[
                const SizedBox(
                  height: 16,
                ),
                _buildCustomVehicleTypeField(),
              ],

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
              // CUSTOMER NUMBER
              // --------------------------------------------------

              _buildCustomerNumberField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // ODOMETER
              // --------------------------------------------------

              _buildOdometerField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // WORK DONE
              // --------------------------------------------------

              _buildWorkDoneField(),

              const SizedBox(
                height: 16,
              ),

              // --------------------------------------------------
              // TOTAL COUNT
              // --------------------------------------------------

              _buildTotalCount(),

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
                      : _saveFleetService,
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
                        : 'Save Fleet Service',
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
  // VEHICLE BRAND DROPDOWN
  // ============================================================

  Widget _buildVehicleBrandDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedVehicleBrand,
      decoration: const InputDecoration(
        labelText: 'Vehicle Brand',
        prefixIcon: Icon(
          Icons.directions_car_outlined,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Toyota',
          child: Text(
            'Toyota',
          ),
        ),
        DropdownMenuItem(
          value: 'Maruti Suzuki',
          child: Text(
            'Maruti Suzuki',
          ),
        ),
      ],
      onChanged: (String? value) {
        setState(() {
          _selectedVehicleBrand = value;

          // ----------------------------------------------------
          // RESET VEHICLE TYPE WHEN BRAND CHANGES
          // ----------------------------------------------------

          _selectedVehicleType = null;

          _customVehicleTypeController.clear();
        });
      },
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select vehicle brand.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // VEHICLE TYPE DROPDOWN
  // ============================================================

  Widget _buildVehicleTypeDropdown() {
    final List<String> vehicleTypes =
    _getVehicleTypes();

    return DropdownButtonFormField<String>(
      initialValue:
      vehicleTypes.contains(
        _selectedVehicleType,
      )
          ? _selectedVehicleType
          : null,
      decoration: const InputDecoration(
        labelText: 'Vehicle Type',
        prefixIcon: Icon(
          Icons.car_repair_outlined,
        ),
      ),
      items: vehicleTypes
          .map(
            (String type) {
          return DropdownMenuItem<String>(
            value: type,
            child: Text(
              type,
            ),
          );
        },
      )
          .toList(),
      onChanged:
      _selectedVehicleBrand == null
          ? null
          : (String? value) {
        setState(() {
          _selectedVehicleType =
              value;

          if (value != 'Other') {
            _customVehicleTypeController
                .clear();
          }
        });
      },
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please select vehicle type.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CUSTOM VEHICLE TYPE
  // ============================================================

  Widget _buildCustomVehicleTypeField() {
    return TextFormField(
      controller:
      _customVehicleTypeController,
      textCapitalization:
      TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Enter Vehicle Type',
        hintText: 'Example: Fortuner',
        prefixIcon: Icon(
          Icons.edit_outlined,
        ),
      ),
      validator: (String? value) {
        if (_selectedVehicleType ==
            'Other') {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Please enter vehicle type.';
          }
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
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter vehicle number.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // CUSTOMER NUMBER
  // ============================================================
  // ============================================================
  // SELECT CUSTOMER
  //
  // Loads customers from the existing Customer Management
  // database and allows the user to search and select one.
  //
  // The customer's contact number is then copied into the
  // Fleet Service Customer Number field.
  // ============================================================

  // ============================================================
// SELECT CUSTOMER
//
// Customer search supports:
//
// - Customer Name
// - Customer Number
//
// If the customer does not exist:
//
// Select Customer
//       ↓
// Create Customer
//       ↓
// Save Customer
//       ↓
// Return to Fleet
//       ↓
// Automatically select customer
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

    if (!mounted || selectedCustomer == null) {
      return;
    }

    setState(() {
      _customerNumberController.text =
          selectedCustomer.phone;
    });
  }
  // ============================================================
  // CUSTOMER NUMBER / CUSTOMER SELECTION
  //
  // Allows the user to select an existing customer from the
  // Customer Management database.
  //
  // The selected customer's phone number is automatically placed
  // into the Customer Number field.
  //
  // Customer Number = Customer Contact Number.
  // ============================================================

  Widget _buildCustomerNumberField() {
    return TextFormField(
      controller: _customerNumberController,

      readOnly: true,

      decoration: InputDecoration(
        labelText: 'Customer Number',
        hintText: 'Select customer',
        prefixIcon: const Icon(
          Icons.phone_outlined,
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
        final String number =
            value?.trim() ?? '';

        if (number.isEmpty) {
          return 'Please select customer.';
        }

        if (!RegExp(
          r'^\d{10}$',
        ).hasMatch(number)) {
          return 'Customer must have a valid 10-digit number.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // ODOMETER
  // ============================================================

  Widget _buildOdometerField() {
    return TextFormField(
      controller:
      _odometerController,
      keyboardType:
      TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Odometer',
        hintText: 'Example: 125430',
        suffixText: 'km',
        prefixIcon: Icon(
          Icons.speed_outlined,
        ),
      ),
      validator: (String? value) {
        final String text =
            value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Please enter odometer reading.';
        }

        final int? number =
        int.tryParse(text);

        if (number == null ||
            number < 0) {
          return 'Enter a valid odometer reading.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // WORK DONE
  // ============================================================

  Widget _buildWorkDoneField() {
    return TextFormField(
      controller:
      _workDoneController,
      textCapitalization:
      TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Work Done',
        hintText: 'Example: Oil Change',
        prefixIcon: Icon(
          Icons.build_outlined,
        ),
      ),
      validator: (String? value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter work done.';
        }

        return null;
      },
    );
  }

  // ============================================================
  // TOTAL COUNT
  // ============================================================

  Widget _buildTotalCount() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Total Count',
        prefixIcon: Icon(
          Icons.numbers_outlined,
        ),
      ),
      child: Text(
        _nextTotalCount.toString(),
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _vehicleNumberController.dispose();

    _customerNumberController.dispose();

    _odometerController.dispose();

    _workDoneController.dispose();

    _customVehicleTypeController.dispose();

    super.dispose();
  }
}
// ============================================================
// CUSTOMER SELECTION DIALOG
//
// Displays existing customers and allows the user to search
// and select one.
//
// Search works using:
// - Customer Name
// - Customer Number / Contact Number
// ============================================================

// ============================================================
// CUSTOMER SELECTION DIALOG
//
// Displays existing customers.
//
// SEARCH:
//
// - Customer Name
// - Customer Number
//
// If no customer exists, the user can create a new customer.
//
// After creating a customer:
//
// Create Customer
//       ↓
// Save
//       ↓
// Return here
//       ↓
// Automatically select new customer
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
  // FILTERED CUSTOMERS
  // ------------------------------------------------------------

  late List<Customer> _filteredCustomers;

  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  // ------------------------------------------------------------

  final CustomerRepository _customerRepository =
  CustomerRepository();

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
  // Searches by:
  //
  // - Customer Name
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
          widget.customers.where(
                (Customer customer) {
              return customer.name
                  .toLowerCase()
                  .contains(search) ||
                  customer.phone
                      .toLowerCase()
                      .contains(search);
            },
          ).toList();
    });
  }

  // ============================================================
  // CREATE CUSTOMER
  //
  // Opens the existing Customer Management screen.
  //
  // After saving, the newly created customer is retrieved and
  // returned to the Fleet Service screen.
  // ============================================================

  Future<void> _createCustomer() async {
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
    // LOAD CUSTOMERS AGAIN
    // ----------------------------------------------------------

    final List<Customer> updatedCustomers =
    await _customerRepository.getCustomers();

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // FIND THE NEWLY CREATED CUSTOMER
    //
    // Customer IDs are automatically generated by SQLite.
    //
    // Because the customer list is ordered newest-first,
    // the first customer is the newly created customer.
    // ----------------------------------------------------------

    if (updatedCustomers.isNotEmpty) {
      final Customer newCustomer =
          updatedCustomers.first;

      Navigator.of(context).pop(
        newCustomer,
      );
    }
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
                hintText:
                'Search name or customer number...',
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
                    onPressed:
                    _createCustomer,
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

                    title: Text(
                      customer.name,
                    ),

                    subtitle: Text(
                      customer.phone,
                    ),

                    trailing:
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),

                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(customer);
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

        // ------------------------------------------------------
        // CREATE CUSTOMER
        //
        // Always available, even when existing customers are
        // displayed.
        // ------------------------------------------------------

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