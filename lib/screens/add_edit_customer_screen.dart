// ============================================================
// FILE: add_edit_customer_screen.dart
//
// PURPOSE:
// Provides the form used to add a new customer or edit an
// existing customer in Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Adds a new customer.
// - Loads an existing customer for editing.
// - Validates customer information.
// - Saves new customers to SQLite.
// - Updates existing customers in SQLite.
// - Returns to the Customer List after saving.
//
// IMPORTANT:
// Customer Number means the customer's contact/mobile number.
// ============================================================

import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../repositories/customer_repository.dart';

// ============================================================
// ADD / EDIT CUSTOMER SCREEN
//
// The same screen is used for both:
//
// Add Customer
//     ↓
// New empty form
//
// Edit Customer
//     ↓
// Existing customer information
// ============================================================

class AddEditCustomerScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // CUSTOMER BEING EDITED
  //
  // If this is null, the screen is being used to add a new
  // customer.
  //
  // If a Customer object is supplied, the screen is being used
  // to edit that customer.
  // ------------------------------------------------------------

  final Customer? customer;

  // ------------------------------------------------------------
  // CONSTRUCTOR
  // ------------------------------------------------------------

  const AddEditCustomerScreen({
    super.key,
    this.customer,
  });

  // ------------------------------------------------------------
  // CHECK WHETHER SCREEN IS IN EDIT MODE
  // ------------------------------------------------------------

  bool get isEditing => customer != null;

  @override
  State<AddEditCustomerScreen> createState() =>
      _AddEditCustomerScreenState();
}

// ============================================================
// ADD / EDIT CUSTOMER SCREEN STATE
// ============================================================

class _AddEditCustomerScreenState
    extends State<AddEditCustomerScreen> {
  // ------------------------------------------------------------
  // CUSTOMER REPOSITORY
  //
  // Handles communication with the SQLite database.
  // ------------------------------------------------------------

  final CustomerRepository _repository =
  CustomerRepository();

  // ------------------------------------------------------------
  // FORM KEY
  //
  // Used to validate the complete form.
  // ------------------------------------------------------------

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ------------------------------------------------------------
  // TEXT CONTROLLERS
  //
  // Each controller manages one input field.
  // ------------------------------------------------------------

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _alternatePhoneController =
  TextEditingController();

  final TextEditingController _addressController =
  TextEditingController();

  final TextEditingController _remarksController =
  TextEditingController();

  // ------------------------------------------------------------
  // SAVE LOADING STATE
  //
  // Prevents the user from pressing Save multiple times while
  // the database operation is running.
  // ------------------------------------------------------------

  bool _isSaving = false;

  // ============================================================
  // INIT STATE
  //
  // Runs when the screen is first created.
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // LOAD EXISTING CUSTOMER INFORMATION
    //
    // Only happens when editing an existing customer.
    // ----------------------------------------------------------

    _loadExistingCustomer();
  }

  // ============================================================
  // LOAD EXISTING CUSTOMER
  //
  // Copies existing customer information into the form fields.
  // ============================================================

  void _loadExistingCustomer() {
    // ----------------------------------------------------------
    // GET CUSTOMER
    // ----------------------------------------------------------

    final Customer? customer =
        widget.customer;

    // ----------------------------------------------------------
    // ADD MODE
    //
    // There is no existing customer to load.
    // ----------------------------------------------------------

    if (customer == null) {
      return;
    }

    // ----------------------------------------------------------
    // POPULATE FORM FIELDS
    // ----------------------------------------------------------

    _nameController.text =
        customer.name;

    _phoneController.text =
        customer.phone;

    _alternatePhoneController.text =
        customer.alternatePhone ?? '';

    _addressController.text =
        customer.address ?? '';

    _remarksController.text =
        customer.remarks ?? '';
  }

  // ============================================================
  // DISPOSE
  //
  // Releases all text controllers when the screen is removed.
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _addressController.dispose();
    _remarksController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE CUSTOMER
  //
  // Handles both:
  //
  // New customer → INSERT
  //
  // Existing customer → UPDATE
  // ============================================================

  Future<void> _saveCustomer() async {
    // ----------------------------------------------------------
    // VALIDATE FORM
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // PREVENT DUPLICATE SAVE OPERATIONS
    // ----------------------------------------------------------

    if (_isSaving) {
      return;
    }

    // ----------------------------------------------------------
    // SHOW SAVING STATE
    // ----------------------------------------------------------

    setState(() {
      _isSaving = true;
    });

    try {
      // --------------------------------------------------------
      // CREATE CUSTOMER OBJECT
      //
      // We use the existing ID when editing.
      // For a new customer, the ID remains null and SQLite
      // generates it automatically.
      // --------------------------------------------------------

      final Customer customer =
      Customer(
        id: widget.customer?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        alternatePhone:
        _emptyToNull(
          _alternatePhoneController.text,
        ),
        address:
        _emptyToNull(
          _addressController.text,
        ),
        remarks:
        _emptyToNull(
          _remarksController.text,
        ),
      );

      // --------------------------------------------------------
      // EDIT EXISTING CUSTOMER
      // --------------------------------------------------------

      if (widget.isEditing) {
        await _repository.updateCustomer(
          customer,
        );
      }

      // --------------------------------------------------------
      // ADD NEW CUSTOMER
      // --------------------------------------------------------

      else {
        await _repository.addCustomer(
          customer,
        );
      }

      // --------------------------------------------------------
      // CHECK WHETHER SCREEN IS STILL ACTIVE
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // RETURN TO CUSTOMER LIST
      //
      // true tells the previous screen that a customer was
      // successfully saved.
      // --------------------------------------------------------

      Navigator.of(context).pop(true);
    } catch (error) {
      // --------------------------------------------------------
      // CHECK WHETHER SCREEN IS STILL ACTIVE
      // --------------------------------------------------------

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // SHOW ERROR MESSAGE
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save customer: $error',
          ),
        ),
      );
    } finally {
      // --------------------------------------------------------
      // STOP SAVING INDICATOR
      // --------------------------------------------------------

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // EMPTY TO NULL
  //
  // Converts an empty optional field into null.
  //
  // This keeps the database clean instead of storing empty
  // strings for optional information.
  // ============================================================

  String? _emptyToNull(String value) {
    final String trimmed =
    value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  // ============================================================
  // CUSTOMER NAME VALIDATOR
  // ============================================================

  String? _validateName(String? value) {
    // ----------------------------------------------------------
    // CHECK EMPTY NAME
    // ----------------------------------------------------------

    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter customer name.';
    }

    // ----------------------------------------------------------
    // MINIMUM NAME LENGTH
    // ----------------------------------------------------------

    if (value.trim().length < 2) {
      return 'Customer name is too short.';
    }

    return null;
  }

  // ============================================================
  // CUSTOMER NUMBER VALIDATOR
  //
  // Customer Number is the customer's contact/mobile number.
  // ============================================================

  String? _validatePhone(String? value) {
    // ----------------------------------------------------------
    // CHECK EMPTY NUMBER
    // ----------------------------------------------------------

    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter customer number.';
    }

    // ----------------------------------------------------------
    // REMOVE SPACES
    // ----------------------------------------------------------

    final String phone =
    value.trim();

    // ----------------------------------------------------------
    // CHECK WHETHER NUMBER CONTAINS ONLY DIGITS
    // ----------------------------------------------------------

    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Customer number must contain only digits.';
    }

    // ----------------------------------------------------------
    // CHECK 10 DIGITS
    // ----------------------------------------------------------

    if (phone.length != 10) {
      return 'Customer number must be 10 digits.';
    }

    return null;
  }

  // ============================================================
  // ALTERNATE NUMBER VALIDATOR
  //
  // This field is optional.
  // ============================================================

  String? _validateAlternatePhone(String? value) {
    // ----------------------------------------------------------
    // OPTIONAL FIELD
    // ----------------------------------------------------------

    if (value == null ||
        value.trim().isEmpty) {
      return null;
    }

    final String phone =
    value.trim();

    // ----------------------------------------------------------
    // ONLY DIGITS
    // ----------------------------------------------------------

    if (!RegExp(r'^\d+$').hasMatch(phone)) {
      return 'Alternate number must contain only digits.';
    }

    // ----------------------------------------------------------
    // CHECK 10 DIGITS
    // ----------------------------------------------------------

    if (phone.length != 10) {
      return 'Alternate number must be 10 digits.';
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit Customer'
              : 'Add Customer',
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SafeArea(
        child: Form(
          key: _formKey,

          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [
              // ==================================================
              // CUSTOMER NAME
              // ==================================================

              TextFormField(
                controller:
                _nameController,

                textInputAction:
                TextInputAction.next,

                textCapitalization:
                TextCapitalization.words,

                decoration:
                const InputDecoration(
                  labelText:
                  'Customer Name',
                  hintText:
                  'Enter customer name',
                  prefixIcon:
                  Icon(
                    Icons.person_outline,
                  ),
                ),

                validator:
                _validateName,
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // CUSTOMER NUMBER
              // ==================================================

              TextFormField(
                controller:
                _phoneController,

                keyboardType:
                TextInputType.phone,

                textInputAction:
                TextInputAction.next,

                maxLength: 10,

                decoration:
                const InputDecoration(
                  labelText:
                  'Customer Number',
                  hintText:
                  'Enter 10-digit contact number',
                  prefixIcon:
                  Icon(
                    Icons.phone_outlined,
                  ),
                  counterText: '',
                ),

                validator:
                _validatePhone,
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // ALTERNATE NUMBER
              // ==================================================

              TextFormField(
                controller:
                _alternatePhoneController,

                keyboardType:
                TextInputType.phone,

                textInputAction:
                TextInputAction.next,

                maxLength: 10,

                decoration:
                const InputDecoration(
                  labelText:
                  'Alternate Number',
                  hintText:
                  'Optional',
                  prefixIcon:
                  Icon(
                    Icons.phone_android_outlined,
                  ),
                  counterText: '',
                ),

                validator:
                _validateAlternatePhone,
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // ADDRESS
              // ==================================================

              TextFormField(
                controller:
                _addressController,

                textInputAction:
                TextInputAction.next,

                textCapitalization:
                TextCapitalization.sentences,

                maxLines: 3,

                decoration:
                const InputDecoration(
                  labelText:
                  'Address',
                  hintText:
                  'Enter customer address',
                  prefixIcon:
                  Icon(
                    Icons.location_on_outlined,
                  ),
                  alignLabelWithHint:
                  true,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // REMARKS
              // ==================================================

              TextFormField(
                controller:
                _remarksController,

                textInputAction:
                TextInputAction.done,

                textCapitalization:
                TextCapitalization.sentences,

                maxLines: 3,

                decoration:
                const InputDecoration(
                  labelText:
                  'Remarks',
                  hintText:
                  'Optional',
                  prefixIcon:
                  Icon(
                    Icons.notes_outlined,
                  ),
                  alignLabelWithHint:
                  true,
                ),
              ),

              const SizedBox(
                height: 28,
              ),

              // ==================================================
              // SAVE BUTTON
              // ==================================================

              SizedBox(
                height: 52,

                child: FilledButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveCustomer,

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
                        : widget.isEditing
                        ? 'Update Customer'
                        : 'Save Customer',
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