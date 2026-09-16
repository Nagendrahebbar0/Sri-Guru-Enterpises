import 'package:flutter/material.dart';

import '../models/gst_setting.dart';
import '../repositories/gst_settings_repository.dart';

/// Screen used to configure the default GST rate for new tyre invoices.
///
/// The user enters only the total GST percentage.
/// SGST and CGST are automatically divided equally.
class GstSettingsScreen extends StatefulWidget {
  const GstSettingsScreen({super.key});

  @override
  State<GstSettingsScreen> createState() => _GstSettingsScreenState();
}

class _GstSettingsScreenState extends State<GstSettingsScreen> {
  // Repository used to read and save GST settings in SQLite.
  final GstSettingsRepository _repository = GstSettingsRepository();

  // Controller for the total GST rate input field.
  final TextEditingController _gstController = TextEditingController();

  // Holds the GST setting currently stored in the database.
  GstSetting? _currentSetting;

  // Indicates whether the saved GST setting is being loaded.
  bool _isLoading = true;

  // Indicates whether a new GST rate is currently being saved.
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Load the existing GST setting when the screen opens.
    _loadSettings();
  }

  @override
  void dispose() {
    // Release the text controller when the screen is removed.
    _gstController.dispose();
    super.dispose();
  }

  /// Loads the current GST setting from SQLite.
  Future<void> _loadSettings() async {
    try {
      final setting = await _repository.getCurrentSetting();

      if (mounted) {
        setState(() {
          _currentSetting = setting;

          // Display the saved total GST rate in the input field.
          if (setting != null) {
            _gstController.text = _formatRate(
              setting.totalGstRate,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to load GST settings.',
          isError: true,
        );
      }
    }

    // Update the loading state only after the database operation
    // has completed. This avoids returning from a finally block.
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Formats a GST percentage without unnecessary decimal zeroes.
  ///
  /// Examples:
  /// 18.0 -> 18
  /// 12.0 -> 12
  /// 17.5 -> 17.5
  String _formatRate(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  /// Converts the value entered in the GST field into a number.
  double? _parseGstRate() {
    final text = _gstController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    return double.tryParse(text);
  }

  /// Validates and saves the total GST rate.
  ///
  /// Only the total GST rate is stored as the setting.
  /// The GstSetting model automatically calculates:
  ///
  /// SGST = Total GST / 2
  /// CGST = Total GST / 2
  Future<void> _saveSettings() async {
    // Hide the keyboard before saving.
    FocusScope.of(context).unfocus();

    final totalGstRate = _parseGstRate();

    // GST rate is required.
    if (totalGstRate == null) {
      _showMessage(
        'Please enter the total GST rate.',
        isError: true,
      );
      return;
    }

    // Keep the GST rate within a valid percentage range.
    if (totalGstRate < 0 || totalGstRate > 100) {
      _showMessage(
        'GST rate must be between 0% and 100%.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Save the total GST rate to SQLite.
      //
      // SGST and CGST are automatically derived from the
      // total rate and do not need separate user input.
      final savedSetting =
      await _repository.saveTotalGstRate(totalGstRate);

      if (mounted) {
        setState(() {
          _currentSetting = savedSetting;

          // Update the input field using the value actually
          // saved by the repository.
          _gstController.text = _formatRate(
            savedSetting.totalGstRate,
          );
        });

        _showMessage(
          'GST settings saved successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Unable to save GST settings.',
          isError: true,
        );
      }
    }

    // Stop the saving indicator after the operation completes.
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Displays a floating message at the bottom of the screen.
  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Settings'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explains how the GST setting works.
              _buildInformationCard(),

              const SizedBox(height: 20),

              // Allows the user to enter the total GST rate.
              _buildGstInputCard(),

              const SizedBox(height: 20),

              // Displays the GST rate currently stored in SQLite.
              _buildCurrentRateCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the information card explaining the GST calculation.
  Widget _buildInformationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GST Rate',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Enter the total GST rate used for new tyre '
                        'invoices. The application automatically '
                        'divides it equally between SGST and CGST.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the GST input and automatic SGST/CGST calculation section.
  Widget _buildGstInputCard() {
    final totalGstRate = _parseGstRate() ?? 0;

    // SGST and CGST are always equal halves of the total GST.
    final halfRate = totalGstRate / 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Default Total GST Rate',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // The user enters only the total GST rate.
            TextFormField(
              controller: _gstController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total GST Rate',
                hintText: 'Example: 18',
                suffixText: '%',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
              ),

              // Recalculate the displayed SGST and CGST
              // whenever the user changes the total rate.
              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(height: 16),

            // Shows the automatic GST split.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: Column(
                children: [
                  _buildRateRow(
                    'Total GST',
                    '${_formatRate(totalGstRate)}%',
                  ),

                  const Divider(height: 20),

                  _buildRateRow(
                    'SGST',
                    '${_formatRate(halfRate)}%',
                  ),

                  const SizedBox(height: 8),

                  _buildRateRow(
                    'CGST',
                    '${_formatRate(halfRate)}%',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Saves the GST setting to SQLite.
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save GST Settings',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds one row displaying a GST rate value.
  Widget _buildRateRow(
      String title,
      String value,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Displays the GST values currently saved in SQLite.
  Widget _buildCurrentRateCard() {
    final setting = _currentSetting;

    // No GST setting has been saved yet.
    if (setting == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No GST rate has been saved yet.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Currently Saved',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _buildRateRow(
              'Total GST',
              '${_formatRate(setting.totalGstRate)}%',
            ),

            const SizedBox(height: 10),

            _buildRateRow(
              'SGST',
              '${_formatRate(setting.sgstRate)}%',
            ),

            const SizedBox(height: 10),

            _buildRateRow(
              'CGST',
              '${_formatRate(setting.cgstRate)}%',
            ),
          ],
        ),
      ),
    );
  }
}