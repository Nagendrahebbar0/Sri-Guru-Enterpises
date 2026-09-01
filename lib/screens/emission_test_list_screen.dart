// ============================================================
// FILE: emission_test_list_screen.dart
//
// PURPOSE:
// Displays all Emission Test records for Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Displays Emission Test records.
// - Searches by customer name.
// - Searches by vehicle number.
// - Searches by BBTDU ID.
// - Adds a new Emission Test.
// - Edits an existing Emission Test.
// - Duplicates an existing Emission Test.
// - Deletes an Emission Test.
// - Refreshes automatically after changes.
//
// CARD COLOR:
// Light Orange.
//
// CUSTOMER CONNECTION:
// Customer Name is selected from Customer Management when
// creating or editing an Emission Test.
//
// IMPORTANT:
// BBTDU ID No. is optional.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/emission_test.dart';
import '../repositories/emission_test_repository.dart';
import 'add_edit_emission_test_screen.dart';

// ============================================================
// EMISSION TEST LIST SCREEN
// ============================================================

class EmissionTestListScreen extends StatefulWidget {
  const EmissionTestListScreen({
    super.key,
  });

  @override
  State<EmissionTestListScreen> createState() =>
      _EmissionTestListScreenState();
}

// ============================================================
// STATE
// ============================================================

class _EmissionTestListScreenState
    extends State<EmissionTestListScreen> {
  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final EmissionTestRepository _repository =
  EmissionTestRepository();

  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // EMISSION RECORDS
  // ------------------------------------------------------------

  List<EmissionTest> _emissionTests = [];

  // ------------------------------------------------------------
  // LOADING STATE
  // ------------------------------------------------------------

  bool _isLoading = true;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadEmissionTests();
  }

  // ============================================================
  // LOAD EMISSION TESTS
  // ============================================================

  Future<void> _loadEmissionTests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String search =
      _searchController.text.trim();

      final List<EmissionTest> records =
      search.isEmpty
          ? await _repository.getEmissionTests()
          : await _repository.searchEmissionTests(
        search,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _emissionTests = records;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Unable to load Emission Tests.',
      );
    }
  }

  // ============================================================
  // SEARCH CHANGED
  // ============================================================

  void _onSearchChanged() {
    _loadEmissionTests();
  }

  // ============================================================
  // ADD EMISSION TEST
  // ============================================================

  Future<void> _addEmissionTest() async {
    final bool? changed =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return const AddEditEmissionTestScreen();
        },
      ),
    );

    if (changed == true) {
      await _loadEmissionTests();
    }
  }

  // ============================================================
  // EDIT EMISSION TEST
  // ============================================================

  Future<void> _editEmissionTest(
      EmissionTest emissionTest,
      ) async {
    final bool? changed =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return AddEditEmissionTestScreen(
            emissionTest: emissionTest,
          );
        },
      ),
    );

    if (changed == true) {
      await _loadEmissionTests();
    }
  }

  // ============================================================
  // DUPLICATE EMISSION TEST
  // ============================================================

  Future<void> _duplicateEmissionTest(
      EmissionTest emissionTest,
      ) async {
    final bool? changed =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) {
          return AddEditEmissionTestScreen(
            emissionTest: emissionTest,
            isDuplicate: true,
          );
        },
      ),
    );

    if (changed == true) {
      await _loadEmissionTests();
    }
  }

  // ============================================================
  // DELETE EMISSION TEST
  // ============================================================

  Future<void> _deleteEmissionTest(
      EmissionTest emissionTest,
      ) async {
    if (emissionTest.id == null) {
      return;
    }

    // ----------------------------------------------------------
    // CONFIRM DELETE
    // ----------------------------------------------------------

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Emission Test?',
          ),
          content: Text(
            'Delete the emission test for '
                '${emissionTest.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    // ----------------------------------------------------------
    // DELETE
    // ----------------------------------------------------------

    try {
      await _repository.deleteEmissionTest(
        emissionTest.id!,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Emission Test deleted.',
      );

      await _loadEmissionTests();
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to delete Emission Test.',
      );
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --------------------------------------------------------
      // SEARCH BAR
      // --------------------------------------------------------

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                'Search name, vehicle or BBTDU ID...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchController.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                ),
              ),
            ),
          ),

          // ----------------------------------------------------
          // CONTENT
          // ----------------------------------------------------

          Expanded(
            child: _buildContent(),
          ),
        ],
      ),

      // --------------------------------------------------------
      // ADD BUTTON
      // --------------------------------------------------------

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _addEmissionTest,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Emission',
        ),
      ),
    );
  }

  // ============================================================
  // BUILD CONTENT
  // ============================================================

  Widget _buildContent() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // ----------------------------------------------------------
    // EMPTY
    // ----------------------------------------------------------

    if (_emissionTests.isEmpty) {
      return _buildEmptyState();
    }

    // ----------------------------------------------------------
    // LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      onRefresh: _loadEmissionTests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          100,
        ),
        itemCount: _emissionTests.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final EmissionTest emissionTest =
          _emissionTests[index];

          return _buildEmissionCard(
            emissionTest,
          );
        },
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              isSearching
                  ? Icons.search_off
                  : Icons.air,
              size: 64,
            ),
            const SizedBox(
              height: 16,
            ),
            Text(
              isSearching
                  ? 'No Emission Tests found.'
                  : 'No Emission Tests yet.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 8,
            ),
            if (!isSearching)
              const Text(
                'Tap "Add Emission" to create a record.',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMISSION CARD
  //
  // Light Orange card.
  // ============================================================

  Widget _buildEmissionCard(
      EmissionTest emissionTest,
      ) {
    return Card(
      color: Colors.orange.shade50,
      elevation: 2,
      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    emissionTest.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                // ------------------------------------------------
                // ACTION MENU
                // ------------------------------------------------

                PopupMenuButton<String>(
                  onSelected: (
                      String value,
                      ) {
                    switch (value) {
                      case 'edit':
                        _editEmissionTest(
                          emissionTest,
                        );
                        break;

                      case 'duplicate':
                        _duplicateEmissionTest(
                          emissionTest,
                        );
                        break;

                      case 'delete':
                        _deleteEmissionTest(
                          emissionTest,
                        );
                        break;
                    }
                  },
                  itemBuilder:
                      (
                      BuildContext context,
                      ) {
                    return const [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          leading: Icon(
                            Icons.edit_outlined,
                          ),
                          title: Text(
                            'Edit',
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'duplicate',
                        child: ListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          leading: Icon(
                            Icons.copy_outlined,
                          ),
                          title: Text(
                            'Duplicate',
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          contentPadding:
                          EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_outline,
                          ),
                          title: Text(
                            'Delete',
                          ),
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // --------------------------------------------------
            // DATE
            // --------------------------------------------------

            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Date',
              DateFormat(
                'dd/MM/yyyy',
              ).format(
                emissionTest.date,
              ),
            ),

            // --------------------------------------------------
            // VEHICLE NUMBER
            // --------------------------------------------------

            if (emissionTest.vehicleNumber != null &&
                emissionTest.vehicleNumber!
                    .trim()
                    .isNotEmpty)
              _buildInfoRow(
                Icons.directions_car_outlined,
                'Vehicle',
                emissionTest.vehicleNumber!,
              ),

            // --------------------------------------------------
            // INCOME
            // --------------------------------------------------

            _buildInfoRow(
              Icons.currency_rupee,
              'Income',
              _formatIncome(
                emissionTest.income,
              ),
            ),

            // --------------------------------------------------
            // BBTDU ID
            //
            // Display only when available.
            // --------------------------------------------------

            if (emissionTest.bbtdUIdNo != null &&
                emissionTest.bbtdUIdNo!
                    .trim()
                    .isNotEmpty)
              _buildInfoRow(
                Icons.badge_outlined,
                'BBTDU ID',
                emissionTest.bbtdUIdNo!,
              ),

            // --------------------------------------------------
            // FUEL TYPE
            // --------------------------------------------------

            _buildInfoRow(
              Icons.local_gas_station_outlined,
              'Fuel',
              emissionTest.fuelType,
            ),

            // --------------------------------------------------
            // PAYMENT METHOD
            // --------------------------------------------------

            _buildInfoRow(
              Icons.payment_outlined,
              'Payment',
              emissionTest.paymentMethod,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FORMAT INCOME
  // ============================================================

  String _formatIncome(
      double income,
      ) {
    if (income == income.roundToDouble()) {
      return '₹${income.toInt()}';
    }

    return '₹${income.toStringAsFixed(2)}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }
}