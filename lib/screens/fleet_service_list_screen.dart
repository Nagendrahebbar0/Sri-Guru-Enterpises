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
// - Calculates next Fleet Service date.
// - Shows Fleet Service reminder status.
// - Opens normal SMS application for reminders.
//
// IMPORTANT:
// - This screen is designed for MOBILE only.
// - Customer Number means customer's contact/mobile number.
// - SMS is NOT automatically sent.
// - The normal SMS application is opened with the message
//   pre-filled.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'add_edit_fleet_service_screen.dart';
import '../models/fleet_service.dart';
import '../repositories/fleet_service_repository.dart';
import '../services/fleet_service_reminder_service.dart';
import '../services/sms_service.dart';
import '../services/sms_reminder_tracker_service.dart';

// ============================================================
// FLEET SERVICE LIST SCREEN
// ============================================================

class FleetServiceListScreen extends StatefulWidget {
  const FleetServiceListScreen({super.key});

  @override
  State<FleetServiceListScreen> createState() =>
      _FleetServiceListScreenState();
}

class _FleetServiceListScreenState extends State<FleetServiceListScreen> {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final FleetServiceRepository _repository = FleetServiceRepository();

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  List<FleetService> _services = [];
  List<FleetService> _filteredServices = [];

  bool _isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_filterServices);

    _loadServices();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.removeListener(_filterServices);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD SERVICES
  // ============================================================

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<FleetService> services =
      await _repository.getFleetServices();

      if (!mounted) return;

      setState(() {
        _services = services;
        _filteredServices = services;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        'Failed to load Fleet Services: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SEARCH / FILTER
  // ============================================================

  void _filterServices() {
    final String query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredServices = List<FleetService>.from(_services);
      });

      return;
    }

    setState(() {
      _filteredServices = _services.where((service) {
        final String vehicleNumber =
        service.vehicleNumber.toLowerCase();

        final String customerNumber =
        service.customerNumber.toLowerCase();

        final String vehicleBrand =
        service.vehicleBrand.toLowerCase();

        final String vehicleType =
        service.vehicleType.toLowerCase();

        final String workDone =
        service.workDone.toLowerCase();

        return vehicleNumber.contains(query) ||
            customerNumber.contains(query) ||
            vehicleBrand.contains(query) ||
            vehicleType.contains(query) ||
            workDone.contains(query);
      }).toList();
    });
  }

  // ============================================================
  // ADD SERVICE
  // ============================================================

  Future<void> _addService() async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditFleetServiceScreen(),
      ),
    );

    if (result == true) {
      await _loadServices();
    }
  }

  // ============================================================
  // EDIT SERVICE
  // ============================================================

  Future<void> _editService(FleetService service) async {
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditFleetServiceScreen(
          fleetService: service,
        ),
      ),
    );

    if (result == true) {
      await _loadServices();
    }
  }

  // ============================================================
  // DUPLICATE SERVICE
  // ============================================================

  Future<void> _duplicateService(
      FleetService service,
      ) async {
    // Open the same form with duplicate mode enabled.
    // This creates a NEW record when the user saves it.
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFleetServiceScreen(
          fleetService: service,
          isDuplicate: true,
        ),
      ),
    );

    if (result == true) {
      await _loadServices();
    }
  }

  // ============================================================
  // DELETE SERVICE
  // ============================================================

  Future<void> _deleteService(FleetService service) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Fleet Service'),
          content: const Text(
            'Are you sure you want to delete this Fleet Service record?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (service.id == null) {
        return;
      }

      await _repository.deleteFleetService(service.id!);
      await SmsReminderTrackerService.clearFleetServiceTracking(recordId: service.id!);

      if (!mounted) return;

      _showMessage(
        'Fleet Service deleted successfully.',
      );

      await _loadServices();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to delete Fleet Service: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // SEND FLEET SERVICE REMINDER SMS
  // ============================================================

  Future<bool> _sendFleetServiceReminderSms(FleetService service) async {
    final DateTime nextServiceDate = FleetServiceReminderService.calculateNextServiceDate(service.date);
    final String customerNumber = service.customerNumber.trim();
    if (customerNumber.isEmpty) { _showMessage('Customer number is not available for this service.', isError: true); return false; }
    final String formattedDate = DateFormat('dd/MM/yyyy').format(nextServiceDate);
    final String message = '''
Dear Customer,

This is a reminder from Sri Guru Enterprises.

Your vehicle ${service.vehicleNumber} is due for its next Fleet Service on $formattedDate.

Kindly bring your vehicle for service to keep it in good condition.

Thank you,
Sri Guru Enterprises
''';
    try {
      final bool opened = await SmsService.openSms(phoneNumber: customerNumber, message: message.trim());
      if (!opened) { if (mounted) _showMessage('Unable to open the SMS application.', isError: true); return false; }
      return true;
    } catch (e) {
      if (mounted) _showMessage('Unable to open SMS: $e', isError: true);
      return false;
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  // ============================================================
  // NEXT SERVICE REMINDER SECTION
  // ============================================================

  Widget _buildNextServiceReminder(
      FleetService service,
      ) {
    final DateTime nextServiceDate =
    FleetServiceReminderService.calculateNextServiceDate(
      service.date,
    );

    final int daysUntil =
    FleetServiceReminderService.daysUntilService(
      nextServiceDate,
    );

    final String status =
    FleetServiceReminderService.getStatus(
      nextServiceDate,
    );

    final bool reminderDue =
    FleetServiceReminderService.isReminderDue(nextServiceDate);
    final int reminderDay = FleetServiceReminderService.getReminderDays(nextServiceDate) ?? (daysUntil == 0 ? 0 : -1);

    final String formattedNextService =
    DateFormat('dd/MM/yyyy').format(nextServiceDate);

    Color statusColor;

    if (FleetServiceReminderService.isOverdue(nextServiceDate)) {
      statusColor = Colors.red;
    } else if (FleetServiceReminderService.isDueToday(
      nextServiceDate,
    )) {
      statusColor = Colors.orange;
    } else if (reminderDue) {
      statusColor = Colors.deepOrange;
    } else {
      statusColor = Colors.green;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------
          // NEXT SERVICE DATE
          // ------------------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.event_available,
                size: 20,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              const Text(
                'Next Fleet Service:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                formattedNextService,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ------------------------------------------------------------
          // STATUS
          // ------------------------------------------------------------

          Row(
            children: [
              const Text(
                'Status: ',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // ------------------------------------------------------------
          // DAYS REMAINING
          // ------------------------------------------------------------

          if (daysUntil > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$daysUntil day${daysUntil == 1 ? '' : 's'} remaining',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ],

          // ------------------------------------------------------------
          // SMS BUTTON
          // ------------------------------------------------------------

          if (reminderDue) ...[
            const SizedBox(height: 10),
            FutureBuilder<bool>(
              future: service.id == null ? Future<bool>.value(false) : SmsReminderTrackerService.isFleetReminderSent(recordId: service.id!, reminderDay: reminderDay),
              builder: (context, snapshot) {
                if (snapshot.data == true) return const SizedBox.shrink();
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final bool opened = await _sendFleetServiceReminderSms(service);
                      if (!opened || service.id == null) return;
                      await SmsReminderTrackerService.markFleetReminderSent(recordId: service.id!, reminderDay: reminderDay);
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.sms),
                    label: const Text('Send Service Reminder SMS'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Services'),
      ),

      // ============================================================
      // ADD BUTTON
      // ============================================================

      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // ============================================================
          // SEARCH BAR
          // ============================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              10,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                'Search vehicle, customer or service...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(Icons.clear),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ============================================================
          // CONTENT
          // ============================================================

          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : _filteredServices.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  90,
                ),
                itemCount: _filteredServices.length,
                itemBuilder: (context, index) {
                  final FleetService service =
                  _filteredServices[index];

                  return _buildFleetServiceCard(
                    service,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final bool hasSearch =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasSearch
                  ? Icons.search_off
                  : Icons.car_repair,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              hasSearch
                  ? 'No Fleet Services found'
                  : 'No Fleet Services added yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasSearch)
              Text(
                'Tap + to add a Fleet Service.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FLEET SERVICE CARD
  // ============================================================

  Widget _buildFleetServiceCard(
      FleetService service,
      ) {
    final String formattedDate =
    DateFormat('dd/MM/yyyy').format(service.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.lightBlue.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================================
            // HEADER
            // ============================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle icon
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.blue,
                  ),
                ),

                const SizedBox(width: 10),

                // Vehicle information
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${service.vehicleBrand} ${service.vehicleType}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        service.vehicleNumber,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),

                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(height: 1),

            const SizedBox(height: 12),

            // ============================================================
            // CUSTOMER NUMBER
            // ============================================================

            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Customer Number:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    service.customerNumber.isEmpty
                        ? 'Not available'
                        : service.customerNumber,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ============================================================
            // ODOMETER
            // ============================================================

            Row(
              children: [
                Icon(
                  Icons.speed,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Odometer:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${service.odometer}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ============================================================
            // WORK DONE
            // ============================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.build,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Work Done:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    service.workDone.isEmpty
                        ? 'Not specified'
                        : service.workDone,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ============================================================
            // TOTAL COUNT
            // ============================================================

            Row(
              children: [
                Icon(
                  Icons.format_list_numbered,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Total Count:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${service.totalCount}',
                ),
              ],
            ),

            // ============================================================
            // NEXT SERVICE REMINDER
            // ============================================================

            _buildNextServiceReminder(service),

            const SizedBox(height: 12),

            const Divider(height: 1),

            const SizedBox(height: 10),

            // ============================================================
            // ACTION BUTTONS
            // ============================================================

            Row(
              children: [
                // --------------------------------------------------------
                // EDIT
                // --------------------------------------------------------

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _editService(service);
                    },
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                    ),
                    label: const Text('Edit'),
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------------
                // DUPLICATE
                // --------------------------------------------------------

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _duplicateService(service);
                    },
                    icon: const Icon(
                      Icons.copy,
                      size: 18,
                    ),
                    label: const Text('Duplicate'),
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------------
                // DELETE
                // --------------------------------------------------------

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _deleteService(service);
                    },
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                    ),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
