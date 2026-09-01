// ============================================================
// FILE: fleet_service_list_screen.dart
//
// PURPOSE:
// Displays Fleet Service records for Sri Guru Enterprises.
//
// FUNCTIONALITY:
// - Loads Fleet Service records from SQLite.
// - Displays Fleet Service records as mobile-friendly cards.
// - Searches Fleet Service records.
// - Provides Add button.
// - Provides Edit button.
// - Provides Duplicate button.
// - Provides Delete button.
//
// IMPORTANT:
// This screen is designed for MOBILE only.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_edit_fleet_service_screen.dart';
import '../models/fleet_service.dart';
import '../repositories/fleet_service_repository.dart';

// ============================================================
// FLEET SERVICE LIST SCREEN
// ============================================================

class FleetServiceListScreen extends StatefulWidget {
  // ------------------------------------------------------------
  // CONSTRUCTOR
  // ------------------------------------------------------------

  const FleetServiceListScreen({
    super.key,
  });

  @override
  State<FleetServiceListScreen> createState() =>
      _FleetServiceListScreenState();
}

// ============================================================
// STATE
// ============================================================

class _FleetServiceListScreenState
    extends State<FleetServiceListScreen> {
  // ------------------------------------------------------------
  // REPOSITORY
  // ------------------------------------------------------------

  final FleetServiceRepository _repository =
  FleetServiceRepository();

  // ------------------------------------------------------------
  // SEARCH CONTROLLER
  // ------------------------------------------------------------

  final TextEditingController _searchController =
  TextEditingController();

  // ------------------------------------------------------------
  // FLEET SERVICE LIST
  // ------------------------------------------------------------

  List<FleetService> _fleetServices = [];

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

    _loadFleetServices();

    _searchController.addListener(
      _searchFleetServices,
    );
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
  // LOAD FLEET SERVICES
  // ============================================================

  Future<void> _loadFleetServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<FleetService> services =
      await _repository.getFleetServices();

      if (!mounted) {
        return;
      }

      setState(() {
        _fleetServices = services;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showErrorMessage(
        'Unable to load Fleet Services.',
      );
    }
  }

  // ============================================================
  // SEARCH FLEET SERVICES
  // ============================================================

  Future<void> _searchFleetServices() async {
    final String searchText =
    _searchController.text.trim();

    try {
      final List<FleetService> results =
      await _repository.searchFleetServices(
        searchText,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fleetServices = results;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorMessage(
        'Unable to search Fleet Services.',
      );
    }
  }

  // ============================================================
  // DELETE FLEET SERVICE
  // ============================================================

  Future<void> _deleteFleetService(
      FleetService fleetService,
      ) async {
    // ----------------------------------------------------------
    // DATABASE ID MUST EXIST
    // ----------------------------------------------------------

    if (fleetService.id == null) {
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
            'Delete Fleet Service?',
          ),
          content: const Text(
            'This Fleet Service record will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
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
    // DELETE FROM DATABASE
    // ----------------------------------------------------------

    try {
      await _repository.deleteFleetService(
        fleetService.id!,
      );

      await _loadFleetServices();

      if (!mounted) {
        return;
      }

      _showSuccessMessage(
        'Fleet Service deleted.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showErrorMessage(
        'Unable to delete Fleet Service.',
      );
    }
  }

  // ============================================================
  // DUPLICATE FLEET SERVICE
  // ============================================================

  Future<void> _duplicateFleetService(
      FleetService fleetService,
      ) async {
    final bool? result =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddEditFleetServiceScreen(
            fleetService: fleetService,
            isDuplicate: true,
          );
        },
      ),
    );

    if (result == true) {
      await _loadFleetServices();
    }
  }

  // ============================================================
  // ADD FLEET SERVICE
  // ============================================================

  Future<void> _addFleetService() async {
    final bool? result =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const AddEditFleetServiceScreen();
        },
      ),
    );

    if (result == true) {
      await _loadFleetServices();
    }
  }

  // ============================================================
  // EDIT FLEET SERVICE
  // ============================================================

  Future<void> _editFleetService(
      FleetService fleetService,
      ) async {
    final bool? result =
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return AddEditFleetServiceScreen(
            fleetService: fleetService,
          );
        },
      ),
    );

    if (result == true) {
      await _loadFleetServices();
    }
  }

  // ============================================================
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(
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

  void _showErrorMessage(
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
    return Scaffold(
      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Fleet Services',
        ),
      ),

      // --------------------------------------------------------
      // ADD BUTTON
      // --------------------------------------------------------

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFleetService,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Fleet',
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: Column(
        children: [
          // ------------------------------------------------------
          // SEARCH BAR
          // ------------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Search vehicle, customer or service...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
              ),
            ),
          ),

          // ------------------------------------------------------
          // CONTENT
          // ------------------------------------------------------

          Expanded(
            child: _buildContent(),
          ),
        ],
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

    if (_fleetServices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadFleetServices,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 180,
            ),
            Icon(
              Icons.directions_car_outlined,
              size: 64,
            ),
            SizedBox(
              height: 16,
            ),
            Center(
              child: Text(
                'No Fleet Services found.',
              ),
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------------
    // LIST
    // ----------------------------------------------------------

    return RefreshIndicator(
      onRefresh: _loadFleetServices,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          100,
        ),
        itemCount: _fleetServices.length,
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final FleetService fleetService =
          _fleetServices[index];

          return _buildFleetServiceCard(
            fleetService,
          );
        },
      ),
    );
  }

  // ============================================================
  // FLEET SERVICE CARD
  // ============================================================

  Widget _buildFleetServiceCard(
      FleetService fleetService,
      ) {
    return Card(
      color: Colors.lightBlue.shade50,
      margin: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // VEHICLE BRAND + TYPE
            // ----------------------------------------------------

            Row(
              children: [
                CircleAvatar(
                  child: const Icon(
                    Icons.directions_car,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        fleetService.vehicleBrand,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        fleetService.vehicleType,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            // ----------------------------------------------------
            // VEHICLE NUMBER
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.confirmation_number_outlined,
              label: 'Vehicle Number',
              value: fleetService.vehicleNumber,
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // CUSTOMER NUMBER
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.phone_outlined,
              label: 'Customer Number',
              value: fleetService.customerNumber,
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // ODOMETER
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.speed_outlined,
              label: 'Odometer',
              value:
              '${fleetService.odometer} km',
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // WORK DONE
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.build_outlined,
              label: 'Work Done',
              value: fleetService.workDone,
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // DATE
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: DateFormat(
                'dd/MM/yyyy',
              ).format(
                fleetService.date,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ----------------------------------------------------
            // TOTAL COUNT
            // ----------------------------------------------------

            _buildInformationRow(
              icon: Icons.numbers_outlined,
              label: 'Total Count',
              value:
              fleetService.totalCount.toString(),
            ),

            const SizedBox(
              height: 12,
            ),

            const Divider(),

            // ----------------------------------------------------
            // ACTIONS
            // ----------------------------------------------------

            Row(
              children: [
                // ------------------------------------------------
                // EDIT
                // ------------------------------------------------

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _editFleetService(
                        fleetService,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      'Edit',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ------------------------------------------------
                // DUPLICATE
                // ------------------------------------------------

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _duplicateFleetService(
                        fleetService,
                      );
                    },
                    icon: const Icon(
                      Icons.copy_outlined,
                    ),
                    label: const Text(
                      'Duplicate',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                // ------------------------------------------------
                // DELETE
                // ------------------------------------------------

                IconButton(
                  onPressed: () {
                    _deleteFleetService(
                      fleetService,
                    );
                  },
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFORMATION ROW
  // ============================================================

  Widget _buildInformationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
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
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}