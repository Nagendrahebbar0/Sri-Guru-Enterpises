// ============================================================
// FILE: add_edit_tyre_stock_screen.dart
//
// PURPOSE:
// Provides the Add and Edit screen for Tyre Stock.
//
// FIELDS:
// - Franchise
// - Vehicle Type
// - Tyre
// - Pattern
// - Size
// - Stock
// - Sell Price
// - LLP
//
// FIXED OPTIONS:
//
// FRANCHISE:
// - Cherry
// - Tyreplex
//
// VEHICLE TYPE:
// - 2 Wheeler
// - 4 Wheeler
//
// MODE:
// - Add
// - Edit
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

import '../models/tyre_stock.dart';
import '../repositories/tyre_stock_repository.dart';

// ============================================================
// ADD / EDIT TYRE STOCK SCREEN
// ============================================================

class AddEditTyreStockScreen extends StatefulWidget {
  const AddEditTyreStockScreen({
    super.key,
    this.stock,
  });

  // ------------------------------------------------------------
  // NULL = ADD MODE
  // NON-NULL = EDIT MODE
  // ------------------------------------------------------------

  final TyreStock? stock;

  @override
  State<AddEditTyreStockScreen> createState() =>
      _AddEditTyreStockScreenState();
}

// ============================================================
// STATE
// ============================================================

class _AddEditTyreStockScreenState
    extends State<AddEditTyreStockScreen> {
  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _tyreController;

  late final TextEditingController _patternController;

  late final TextEditingController _sizeController;

  late final TextEditingController _stockController;

  late final TextEditingController _sellPriceController;

  late final TextEditingController _llpController;

  // ============================================================
  // REPOSITORY
  // ============================================================

  final TyreStockRepository _repository =
  TyreStockRepository();

  // ============================================================
  // DROPDOWN VALUES
  // ============================================================

  static const List<String> _franchises =
  <String>[
    'Cherry',
    'Tyreplex',
  ];

  static const List<String> _vehicleTypes =
  <String>[
    '2 Wheeler',
    '4 Wheeler',
  ];

  String? _selectedFranchise;

  String? _selectedVehicleType;

  // ============================================================
  // SAVE STATE
  // ============================================================

  bool _isSaving = false;

  // ============================================================
  // EDIT MODE
  // ============================================================

  bool get _isEditMode {
    return widget.stock != null;
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    final TyreStock? stock =
        widget.stock;

    _selectedFranchise =
        stock?.franchise;

    _selectedVehicleType =
        stock?.vehicleType;

    _tyreController =
        TextEditingController(
          text: stock?.tyre ?? '',
        );

    _patternController =
        TextEditingController(
          text: stock?.pattern ?? '',
        );

    _sizeController =
        TextEditingController(
          text: stock?.size ?? '',
        );

    _stockController =
        TextEditingController(
          text: stock?.stock.toString() ?? '0',
        );

    _sellPriceController =
        TextEditingController(
          text: stock == null
              ? ''
              : stock.sellPrice.toStringAsFixed(2),
        );

    _llpController =
        TextEditingController(
          text: stock == null
              ? ''
              : stock.llp.toStringAsFixed(2),
        );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _tyreController.dispose();
    _patternController.dispose();
    _sizeController.dispose();
    _stockController.dispose();
    _sellPriceController.dispose();
    _llpController.dispose();

    super.dispose();
  }

  // ============================================================
  // REQUIRED TEXT VALIDATOR
  // ============================================================

  String? _requiredValidator(
      String? value,
      String fieldName,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }

    return null;
  }

  // ============================================================
  // STOCK VALIDATOR
  // ============================================================

  String? _stockValidator(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter Stock';
    }

    final int? stock =
    int.tryParse(
      value.trim(),
    );

    if (stock == null) {
      return 'Enter a valid whole number';
    }

    if (stock < 0) {
      return 'Stock cannot be negative';
    }

    return null;
  }

  // ============================================================
  // PRICE VALIDATOR
  // ============================================================

  String? _priceValidator(
      String? value,
      String fieldName,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }

    final double? amount =
    double.tryParse(
      value.trim(),
    );

    if (amount == null) {
      return 'Enter a valid amount';
    }

    if (amount < 0) {
      return '$fieldName cannot be negative';
    }

    return null;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    // ----------------------------------------------------------
    // Validate all fields.
    // ----------------------------------------------------------

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ----------------------------------------------------------
    // Validate dropdowns.
    // ----------------------------------------------------------

    if (_selectedFranchise == null) {
      _showMessage(
        'Please select a franchise.',
      );
      return;
    }

    if (_selectedVehicleType == null) {
      _showMessage(
        'Please select vehicle type.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final TyreStock stock =
      TyreStock(
        id: widget.stock?.id,
        franchise: _selectedFranchise!,
        vehicleType: _selectedVehicleType!,
        tyre: _tyreController.text.trim(),
        pattern:
        _patternController.text.trim(),
        size:
        _sizeController.text.trim(),
        stock:
        int.parse(
          _stockController.text.trim(),
        ),
        sellPrice:
        double.parse(
          _sellPriceController.text.trim(),
        ),
        llp:
        double.parse(
          _llpController.text.trim(),
        ),
      );

      // --------------------------------------------------------
      // INSERT
      // --------------------------------------------------------

      if (!_isEditMode) {
        await _repository.insert(stock);
      }

      // --------------------------------------------------------
      // UPDATE
      // --------------------------------------------------------

      else {
        await _repository.update(stock);
      }

      if (!mounted) {
        return;
      }

      _showMessage(
        _isEditMode
            ? 'Tyre stock updated successfully.'
            : 'Tyre stock added successfully.',
      );

      Navigator.of(context).pop(true);
    } on DatabaseException catch (error) {
      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // DUPLICATE STOCK
      // --------------------------------------------------------

      if (error.isUniqueConstraintError()) {
        _showMessage(
          'This franchise already has this tyre, '
              'pattern and size for the selected vehicle type.',
        );
      } else {
        _showMessage(
          'Unable to save tyre stock.',
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to save tyre stock.',
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
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization:
        TextCapitalization.words,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border:
          const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border:
          const OutlineInputBorder(),
        ),
        items: items
            .map(
              (String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          },
        )
            .toList(),
        onChanged: onChanged,
        validator: (String? value) {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Please select $label';
          }

          return null;
        },
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? 'Edit Tyre Stock'
              : 'Add Tyre Stock',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: <Widget>[
                // ------------------------------------------------
                // FRANCHISE
                // ------------------------------------------------

                _buildDropdown(
                  label: 'Franchise',
                  value:
                  _selectedFranchise,
                  items: _franchises,
                  onChanged:
                      (String? value) {
                    setState(() {
                      _selectedFranchise =
                          value;
                    });
                  },
                ),

                // ------------------------------------------------
                // VEHICLE TYPE
                // ------------------------------------------------

                _buildDropdown(
                  label: 'Vehicle Type',
                  value:
                  _selectedVehicleType,
                  items: _vehicleTypes,
                  onChanged:
                      (String? value) {
                    setState(() {
                      _selectedVehicleType =
                          value;
                    });
                  },
                ),

                // ------------------------------------------------
                // TYRE
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _tyreController,
                  label: 'Tyre',
                  hint:
                  'Enter tyre company',
                  validator:
                      (String? value) {
                    return _requiredValidator(
                      value,
                      'Tyre',
                    );
                  },
                ),

                // ------------------------------------------------
                // PATTERN
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _patternController,
                  label: 'Pattern',
                  hint:
                  'Enter pattern',
                  validator:
                      (String? value) {
                    return _requiredValidator(
                      value,
                      'Pattern',
                    );
                  },
                ),

                // ------------------------------------------------
                // SIZE
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _sizeController,
                  label: 'Size',
                  hint:
                  'Example: 185/65 R15',
                  validator:
                      (String? value) {
                    return _requiredValidator(
                      value,
                      'Size',
                    );
                  },
                ),

                // ------------------------------------------------
                // STOCK
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _stockController,
                  label: 'Stock',
                  hint:
                  'Enter available quantity',
                  keyboardType:
                  TextInputType.number,
                  inputFormatters:
                  <TextInputFormatter>[
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],
                  validator:
                  _stockValidator,
                ),

                // ------------------------------------------------
                // SELL PRICE
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _sellPriceController,
                  label: 'Sell Price',
                  hint:
                  'Enter selling price',
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  validator:
                      (String? value) {
                    return _priceValidator(
                      value,
                      'Sell Price',
                    );
                  },
                ),

                // ------------------------------------------------
                // LLP
                // ------------------------------------------------

                _buildTextField(
                  controller:
                  _llpController,
                  label: 'LLP',
                  hint:
                  'Enter LLP',
                  keyboardType:
                  const TextInputType
                      .numberWithOptions(
                    decimal: true,
                  ),
                  validator:
                      (String? value) {
                    return _priceValidator(
                      value,
                      'LLP',
                    );
                  },
                ),

                const SizedBox(
                  height: 8,
                ),

                // ------------------------------------------------
                // SAVE BUTTON
                // ------------------------------------------------

                SizedBox(
                  height: 52,
                  child:
                  FilledButton.icon(
                    onPressed:
                    _isSaving
                        ? null
                        : _save,
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
                      Icons
                          .save_outlined,
                    ),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : 'Save',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}