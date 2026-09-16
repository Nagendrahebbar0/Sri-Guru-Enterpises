// ============================================================
// FILE: gst_verification_screen.dart
// PURPOSE:
// Free GSTIN verification workflow for Sri Guru Enterprises.
//
// WORKFLOW:
// 1. Enter GSTIN.
// 2. Open the official GST Search Taxpayer page.
// 3. User enters the CAPTCHA on the official GST website.
// 4. User verifies the GSTIN and copies the displayed details.
// 5. Return to this screen.
// 6. Paste the copied GST result into the import box.
// 7. The app extracts common GST fields.
// 8. User reviews the extracted details.
// 9. Tap "Use These Details" to return them to Tyre Billing.
//
// IMPORTANT:
// - No paid GST API is used.
// - No CAPTCHA is solved or bypassed.
// - The app does not scrape the GST portal.
// - The user remains in control of the official verification.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gst_taxpayer_details.dart';

class GstVerificationScreen extends StatefulWidget {
  final String initialGstin;

  const GstVerificationScreen({
    super.key,
    this.initialGstin = '',
  });

  @override
  State<GstVerificationScreen> createState() =>
      _GstVerificationScreenState();
}

class _GstVerificationScreenState
    extends State<GstVerificationScreen> {
  static const String _gstSearchUrl =
      'https://services.gst.gov.in/services/quicklinks/searchtxp';

  late final TextEditingController _gstinController;
  final TextEditingController _importController =
      TextEditingController();

  String _legalName = '';
  String _tradeName = '';
  String _address = '';
  String _state = '';
  String _pinCode = '';
  String _status = '';
  String _registrationDate = '';
  String _taxpayerType = '';

  bool _openedPortal = false;

  @override
  void initState() {
    super.initState();

    _gstinController = TextEditingController(
      text: widget.initialGstin.trim().toUpperCase(),
    );
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _importController.dispose();
    super.dispose();
  }

  Future<void> _openGstPortal() async {
    final String gstin =
        _gstinController.text.trim().toUpperCase();

    if (!_isValidGstin(gstin)) {
      _showMessage(
        'Enter a valid 15-character GSTIN before opening the GST portal.',
      );
      return;
    }

    final Uri uri = Uri.parse(_gstSearchUrl);

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage('Unable to open the GST portal.');
        return;
      }

      if (mounted) {
        setState(() {
          _openedPortal = true;
        });
      }
    } catch (_) {
      _showMessage('Unable to open the GST portal.');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? data =
        await Clipboard.getData(Clipboard.kTextPlain);

    final String text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      _showMessage(
        'Nothing was found in the clipboard. Copy the GST search result first.',
      );
      return;
    }

    _importController.text = text;
    _parseImportedText();
  }

  void _parseImportedText() {
    final String text = _importController.text.trim();

    if (text.isEmpty) {
      _showMessage('Paste the GST search result first.');
      return;
    }

    final String enteredGstin =
        _gstinController.text.trim().toUpperCase();

    String extractAfterLabel(List<String> labels) {
      final List<String> lines = text
          .split(RegExp(r'\r?\n'))
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList();

      for (int index = 0; index < lines.length; index++) {
        final String line = lines[index];

        for (final String label in labels) {
          final RegExp pattern = RegExp(
            '^${RegExp.escape(label)}\\s*[:\\-]?\\s*(.*)\$',
            caseSensitive: false,
          );

          final RegExpMatch? match = pattern.firstMatch(line);

          if (match != null) {
            final String value =
                (match.group(1) ?? '').trim();

            if (value.isNotEmpty) {
              return value;
            }

            if (index + 1 < lines.length) {
              return lines[index + 1].trim();
            }
          }
        }
      }

      return '';
    }

    String gstin = _findGstin(text);

    if (gstin.isEmpty) {
      gstin = enteredGstin;
    }

    final String legalName = extractAfterLabel(
      <String>[
        'Legal Name of Business',
        'Legal Name',
      ],
    );

    final String tradeName = extractAfterLabel(
      <String>[
        'Trade Name',
        'Trade Name of Business',
      ],
    );

    final String address = extractAfterLabel(
      <String>[
        'Principal Place of Business',
        'Address',
        'Principal Address',
      ],
    );

    final String state = extractAfterLabel(
      <String>[
        'State',
        'State Jurisdiction',
      ],
    );

    final String pinCode = extractAfterLabel(
      <String>[
        'PIN Code',
        'Pincode',
        'Pin Code',
      ],
    );

    final String status = extractAfterLabel(
      <String>[
        'GSTIN / UIN Status',
        'GSTIN Status',
        'Status',
      ],
    );

    final String registrationDate = extractAfterLabel(
      <String>[
        'Date of Registration',
        'Registration Date',
      ],
    );

    final String taxpayerType = extractAfterLabel(
      <String>[
        'Taxpayer Type',
      ],
    );

    setState(() {
      _legalName = legalName;
      _tradeName = tradeName;
      _address = address;
      _state = state;
      _pinCode = pinCode;
      _status = status;
      _registrationDate = registrationDate;
      _taxpayerType = taxpayerType;

      if (gstin.isNotEmpty) {
        _gstinController.text = gstin.toUpperCase();
      }
    });

    if (legalName.isEmpty &&
        tradeName.isEmpty &&
        address.isEmpty) {
      _showMessage(
        'The text could not be recognised automatically. '
        'Please review the pasted result or enter the details manually.',
      );
      return;
    }

    _showMessage('GST details imported. Please review them.');
  }

  String _findGstin(String text) {
    final RegExp regex = RegExp(
      r'\b\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]Z[A-Z0-9]\b',
      caseSensitive: false,
    );

    return regex.firstMatch(text)?.group(0)?.toUpperCase() ?? '';
  }

  bool _isValidGstin(String gstin) {
    return RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z][A-Z0-9]Z[A-Z0-9]$',
      caseSensitive: false,
    ).hasMatch(gstin);
  }

  void _useDetails() {
    final String gstin =
        _gstinController.text.trim().toUpperCase();

    if (!_isValidGstin(gstin)) {
      _showMessage('Enter a valid GSTIN.');
      return;
    }

    if (_legalName.isEmpty &&
        _tradeName.isEmpty &&
        _address.isEmpty) {
      _showMessage(
        'Import or enter GST details before continuing.',
      );
      return;
    }

    final GstTaxpayerDetails details = GstTaxpayerDetails(
      gstin: gstin,
      legalName: _legalName,
      tradeName: _tradeName,
      address: _address,
      state: _state,
      pinCode: _pinCode,
      status: _status,
      registrationDate: _registrationDate,
      taxpayerType: _taxpayerType,
    );

    Navigator.of(context).pop(details);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildDetail(
    String label,
    String value,
  ) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GST Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Free GSTIN Verification',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use the official GST Search Taxpayer portal. '
                        'You will enter the CAPTCHA yourself.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _gstinController,
                textCapitalization:
                    TextCapitalization.characters,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9]'),
                  ),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: const InputDecoration(
                  labelText: 'GSTIN',
                  hintText: 'Example: 29AFLPR0084H2Z2',
                  prefixIcon: Icon(
                    Icons.verified_user_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openGstPortal,
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text(
                    'Open Official GST Search',
                  ),
                ),
              ),

              if (_openedPortal) ...<Widget>[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'On the GST portal: enter the GSTIN, '
                      'enter the CAPTCHA, search the taxpayer, '
                      'then copy the displayed taxpayer details '
                      'and return here.',
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              Text(
                'Import GST Search Result',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _importController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Paste GST details',
                  hintText:
                      'Paste the text copied from the GST portal here.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste),
                      label: const Text('Paste'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _parseImportedText,
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('Import'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                'Verified GST Details',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              _buildDetail(
                'GSTIN',
                _gstinController.text.trim(),
              ),
              _buildDetail(
                'Legal Name',
                _legalName,
              ),
              _buildDetail(
                'Trade Name',
                _tradeName,
              ),
              _buildDetail(
                'Address',
                _address,
              ),
              _buildDetail(
                'State',
                _state,
              ),
              _buildDetail(
                'PIN Code',
                _pinCode,
              ),
              _buildDetail(
                'Status',
                _status,
              ),
              _buildDetail(
                'Registration Date',
                _registrationDate,
              ),
              _buildDetail(
                'Taxpayer Type',
                _taxpayerType,
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _useDetails,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Use These Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
