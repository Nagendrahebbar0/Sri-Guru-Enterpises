// ============================================================
// FILE: app_shell.dart
//
// PURPOSE:
// Provides the main mobile application shell for Sri Guru
// Enterprises.
//
// FUNCTIONALITY:
// - Displays the main application interface.
// - Provides mobile navigation.
// - Displays the Dashboard.
// - Displays Fleet Service alerts and reminders.
// - Allows Fleet Service reminder SMS directly from Dashboard.
// - Connects Customer, Fleet Service, Emission, Documents
//   and Accessories modules.
//
// NAVIGATION:
//
// 0 → Dashboard
// 1 → Customers
// 2 → Fleet Services
// 3 → Emission
// 4 → More (Documents, Accessories and future modules)
// 4 → Car Documents
// 5 → Accessories
//
// IMPORTANT:
// - Existing Fleet Service reminder logic is reused.
// - Existing SMS service is reused.
// - SMS is NOT automatically sent.
// - The normal SMS application opens with the message
//   pre-filled.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/car_document_list_screen.dart';

// ============================================================
// APPLICATION SCREENS
// ============================================================

import '../screens/customer_list_screen.dart';
import '../screens/fleet_service_list_screen.dart';
import '../screens/emission_test_list_screen.dart';
import '../screens/accessory_list_screen.dart';

// ============================================================
// MODELS
// ============================================================

import '../models/fleet_service.dart';
import '../models/car_document.dart';

// ============================================================
// REPOSITORIES
// ============================================================

import '../repositories/fleet_service_repository.dart';
import '../repositories/car_document_repository.dart';

// ============================================================
// SERVICES
// ============================================================

import '../services/fleet_service_reminder_service.dart';
import '../services/car_document_reminder_service.dart';
import '../services/sms_service.dart';
import '../services/sms_reminder_tracker_service.dart';

// ============================================================
// APP SHELL
// ============================================================

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

// ============================================================
// APP SHELL STATE
// ============================================================

class _AppShellState extends State<AppShell> {
  // ============================================================
  // CURRENT NAVIGATION INDEX
  // ============================================================

  int _currentIndex = 0;

  // ============================================================
  // FLEET SERVICE REPOSITORY
  // ============================================================

  final FleetServiceRepository _fleetRepository =
  FleetServiceRepository();

  final CarDocumentRepository _carDocumentRepository =
  CarDocumentRepository();

  // ============================================================
  // DASHBOARD DATA
  // ============================================================

  List<FleetService> _fleetServices = [];

  List<CarDocument> _carDocuments = [];

  bool _isDashboardLoading = true;

  String? _dashboardError;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboardData();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isDashboardLoading = true;
        _dashboardError = null;
      });
    }

    try {
      final List<FleetService> services =
      await _fleetRepository.getFleetServices();

      final List<CarDocument> documents =
      await _carDocumentRepository.getCarDocuments();

      if (!mounted) return;

      setState(() {
        _fleetServices = services;
        _carDocuments = documents;
        _isDashboardLoading = false;
        _dashboardError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDashboardLoading = false;
        _dashboardError =
        'Failed to load Dashboard alerts.';
      });
    }
  }

  // ============================================================
  // NAVIGATION CHANGE
  //
  // Dashboard is refreshed whenever the user returns to it.
  // ============================================================

  void _onNavigationChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      _loadDashboardData();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected:
        _onNavigationChanged,

        destinations: const [
          // ----------------------------------------------------
          // DASHBOARD
          // ----------------------------------------------------

          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),

          // ----------------------------------------------------
          // CUSTOMERS
          // ----------------------------------------------------

          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),

          // ----------------------------------------------------
          // FLEET
          // ----------------------------------------------------

          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Fleet',
          ),

          // ----------------------------------------------------
          // EMISSION
          // ----------------------------------------------------

          NavigationDestination(
            icon: Icon(Icons.air_outlined),
            selectedIcon: Icon(Icons.air),
            label: 'Emission',
          ),

          // ----------------------------------------------------
          // MORE
          //
          // Documents, Accessories and future modules are kept
          // here so the bottom navigation stays clean on mobile.
          // ----------------------------------------------------

          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
          ],
      ),
    );
  }

  // ============================================================
  // BUILD CURRENT PAGE
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
    // --------------------------------------------------------
    // DASHBOARD
    // --------------------------------------------------------

      case 0:
        return _buildDashboard();

    // --------------------------------------------------------
    // CUSTOMERS
    // --------------------------------------------------------

      case 1:
        return const CustomerListScreen();

    // --------------------------------------------------------
    // FLEET SERVICES
    // --------------------------------------------------------

      case 2:
        return const FleetServiceListScreen();

    // --------------------------------------------------------
    // EMISSION
    // --------------------------------------------------------

      case 3:
        return const EmissionTestListScreen();

    // --------------------------------------------------------
    // MORE
    // --------------------------------------------------------

      case 4:
        return _buildMorePage();

    // --------------------------------------------------------
    // FALLBACK
    // --------------------------------------------------------

      default:
        return _buildDashboard();
    }
  }

  // ============================================================
  // MORE MODULES
  //
  // Secondary and future modules are placed here instead of
  // crowding the bottom navigation bar.
  // ============================================================

  Widget _buildMorePage() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('More'),
            automaticallyImplyLeading: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _buildMoreModuleCard(
                    icon: Icons.description_outlined,
                    title: 'Car Documents',
                    subtitle:
                        'Insurance, permits, road tax and expiry reminders',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const CarDocumentListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMoreModuleCard(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Accessories',
                    subtitle:
                        'Trip Sheet, Bill Book and other accessory items',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const AccessoryListScreen(),
                        ),
                      );
                    },
                  ),

                  // Future modules can be added here without
                  // increasing the number of bottom navigation
                  // buttons.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreModuleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
                child: Icon(
                  icon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,

        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HEADER
              // ==================================================

              _buildDashboardHeader(),

              const SizedBox(height: 20),

              // ==================================================
              // ALERTS
              // ==================================================

              _buildFleetServiceAlerts(),

              const SizedBox(height: 24),

              _buildCarDocumentAlerts(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD HEADER
  // ============================================================

  Widget _buildDashboardHeader() {
    return Card(
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          children: [
            // --------------------------------------------------
            // LOGO
            // --------------------------------------------------

            Image.asset(
              'assets/icon/sri_guru_logo.png',
              width: 64,
              height: 64,
            ),

            const SizedBox(width: 14),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    'Sri Guru Enterprises',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Dashboard',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium,
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // REFRESH
            // --------------------------------------------------

            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadDashboardData,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FLEET SERVICE ALERTS
  // ============================================================

  Widget _buildFleetServiceAlerts() {
    // ----------------------------------------------------------
    // LOADING
    // ----------------------------------------------------------

    if (_isDashboardLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    if (_dashboardError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
              ),

              const SizedBox(height: 10),

              Text(
                _dashboardError!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _loadDashboardData,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // ALERT LISTS
    // ----------------------------------------------------------

    final List<FleetService> overdue = [];

    final List<FleetService> dueToday = [];

    final List<FleetService> reminders = [];

    final List<FleetService> dueSoon = [];

    // ----------------------------------------------------------
    // CHECK EVERY FLEET SERVICE
    // ----------------------------------------------------------

    for (final FleetService service
    in _fleetServices) {
      final DateTime nextServiceDate =
      FleetServiceReminderService
          .calculateNextServiceDate(
        service.date,
      );

      final int daysUntil =
      FleetServiceReminderService
          .daysUntilService(
        nextServiceDate,
      );

      // --------------------------------------------------------
      // OVERDUE
      // --------------------------------------------------------

      if (daysUntil < 0) {
        overdue.add(service);
        continue;
      }

      // --------------------------------------------------------
      // DUE TODAY
      // --------------------------------------------------------

      if (daysUntil == 0) {
        dueToday.add(service);
        continue;
      }

      // --------------------------------------------------------
      // SCHEDULED REMINDER
      //
      // 30, 15, 7 or 1 day before service.
      // --------------------------------------------------------

      if (FleetServiceReminderService
          .reminderDays
          .contains(daysUntil)) {
        reminders.add(service);
        continue;
      }

      // --------------------------------------------------------
      // DUE SOON
      //
      // Within the next 30 days but not a scheduled reminder.
      // --------------------------------------------------------

      if (daysUntil > 0 && daysUntil <= 30) {
        dueSoon.add(service);
      }
    }

    // ----------------------------------------------------------
    // ACTIVE ALERT COUNT
    //
    // Due Soon is informational and is not included here.
    // ----------------------------------------------------------

    final int activeAlertCount =
        overdue.length +
            dueToday.length +
            reminders.length;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [
        // ========================================================
        // SECTION TITLE
        // ========================================================

        Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                'Alerts & Reminders',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            if (activeAlertCount > 0)
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius:
                  BorderRadius.circular(20),
                ),

                child: Text(
                  '$activeAlertCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        // ========================================================
        // SUMMARY CARDS
        // ========================================================

        _buildAlertSummary(
          overdueCount: overdue.length,
          dueTodayCount: dueToday.length,
          reminderCount: reminders.length,
          dueSoonCount: dueSoon.length,
        ),

        const SizedBox(height: 20),

        // ========================================================
        // NO ACTIVE ALERTS
        // ========================================================

        if (activeAlertCount == 0)
          _buildNoActiveAlerts(),

        // ========================================================
        // OVERDUE
        // ========================================================

        if (overdue.isNotEmpty)
          _buildAlertGroup(
            title: 'Overdue',
            icon:
            Icons.warning_amber_rounded,
            status: 'Overdue',
            services: overdue,
          ),

        // ========================================================
        // DUE TODAY
        // ========================================================

        if (dueToday.isNotEmpty)
          _buildAlertGroup(
            title: 'Due Today',
            icon: Icons.today,
            status: 'Due Today',
            services: dueToday,
          ),

        // ========================================================
        // REMINDERS
        // ========================================================

        if (reminders.isNotEmpty)
          _buildAlertGroup(
            title: 'Reminders Due',
            icon:
            Icons.notifications_active,
            status: 'Reminder Due',
            services: reminders,
          ),

        // ========================================================
        // DUE SOON
        // ========================================================

        if (dueSoon.isNotEmpty)
          _buildAlertGroup(
            title: 'Due Soon',
            icon:
            Icons.event_available,
            status: 'Due Soon',
            services: dueSoon,
          ),
      ],
    );
  }

  // ============================================================
  // ALERT SUMMARY
  // ============================================================

  Widget _buildAlertSummary({
    required int overdueCount,
    required int dueTodayCount,
    required int reminderCount,
    required int dueSoonCount,
  }) {
    return Column(
      children: [
        // ========================================================
        // FIRST ROW
        // ========================================================

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Overdue',
                count: overdueCount,
                icon:
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSummaryCard(
                title: 'Due Today',
                count: dueTodayCount,
                icon: Icons.today,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ========================================================
        // SECOND ROW
        // ========================================================

        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Reminders',
                count: reminderCount,
                icon:
                Icons.notifications_active,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _buildSummaryCard(
                title: 'Due Soon',
                count: dueSoonCount,
                icon:
                Icons.event_available,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,

      color: color.withValues(
        alpha: 0.08,
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    '$count',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: color,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ALERT GROUP
  // ============================================================

  Widget _buildAlertGroup({
    required String title,
    required IconData icon,
    required String status,
    required List<FleetService> services,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 20),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // GROUP HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Icon(
                icon,
                size: 22,
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '(${services.length})',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ------------------------------------------------------
          // ALERT CARDS
          // ------------------------------------------------------

          ...services.map(
                (FleetService service) =>
                _buildAlertCard(
                  service: service,
                  status: status,
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALERT CARD
  // ============================================================

  Widget _buildAlertCard({
    required FleetService service,
    required String status,
  }) {
    // ----------------------------------------------------------
    // CALCULATE NEXT SERVICE DATE
    // ----------------------------------------------------------

    final DateTime nextServiceDate =
    FleetServiceReminderService
        .calculateNextServiceDate(
      service.date,
    );

    // ----------------------------------------------------------
    // CALCULATE DAYS
    // ----------------------------------------------------------

    final int daysUntil =
    FleetServiceReminderService
        .daysUntilService(
      nextServiceDate,
    );

    // ----------------------------------------------------------
    // FORMAT DATE
    // ----------------------------------------------------------

    final String formattedDate =
    DateFormat('dd/MM/yyyy')
        .format(nextServiceDate);

    // ----------------------------------------------------------
    // CHECK WHETHER SMS CAN BE SENT
    //
    // This is true for:
    // 30, 15, 7, 1 days
    // Due Today
    // Overdue
    // ----------------------------------------------------------

    final bool canSendSms =
    FleetServiceReminderService
        .isReminderDue(
      nextServiceDate,
    );

    // ----------------------------------------------------------
    // STATUS COLOR
    // ----------------------------------------------------------

    Color statusColor;

    if (status == 'Overdue') {
      statusColor = Colors.red;
    } else if (status == 'Due Today') {
      statusColor = Colors.orange;
    } else if (status == 'Reminder Due') {
      statusColor = Colors.deepOrange;
    } else {
      statusColor = Colors.blue;
    }

    // ----------------------------------------------------------
    // REMAINING TEXT
    // ----------------------------------------------------------

    String remainingText;

    if (daysUntil < 0) {
      final int overdueDays =
      daysUntil.abs();

      remainingText =
      '$overdueDays day'
          '${overdueDays == 1 ? '' : 's'} overdue';
    } else if (daysUntil == 0) {
      remainingText = 'Due today';
    } else {
      remainingText =
      '$daysUntil day'
          '${daysUntil == 1 ? '' : 's'} remaining';
    }

    return Card(
      margin:
      const EdgeInsets.only(bottom: 10),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // VEHICLE + STATUS
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 22,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    service.vehicleNumber
                        .trim()
                        .isEmpty
                        ? 'Vehicle Number Not Available'
                        : service.vehicleNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),

                  decoration: BoxDecoration(
                    color:
                    statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),

                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // CUSTOMER NUMBER
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    service.customerNumber
                        .trim()
                        .isEmpty
                        ? 'Customer Number Not Available'
                        : service.customerNumber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ==================================================
            // NEXT SERVICE
            // ==================================================

            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 18,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    'Next Service: $formattedDate',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ==================================================
            // REMAINING DAYS
            // ==================================================

            Row(
              children: [
                Icon(
                  daysUntil <= 0
                      ? Icons.warning_amber_rounded
                      : Icons.schedule,
                  size: 18,
                  color: statusColor,
                ),

                const SizedBox(width: 8),

                Text(
                  remainingText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),

            // ==================================================
            // SEND SMS
            // ==================================================

            if (canSendSms && service.id != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _isFleetReminderAlreadySent(
                  service,
                  nextServiceDate,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 44,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.data == true) {
                    return _buildSmsSentLabel();
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final bool opened =
                        await _sendFleetServiceReminderSms(service);
                        if (!opened || !mounted || service.id == null) return;

                        await SmsReminderTrackerService.markFleetReminderSent(
                          recordId: service.id!,
                          reminderDay: _getFleetReminderDay(nextServiceDate),
                        );

                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Send Service Reminder SMS'),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAR DOCUMENT EXPIRY ALERTS
  // ============================================================

  Widget _buildCarDocumentAlerts() {
    final List<CarDocument> overdue = [];
    final List<CarDocument> dueToday = [];
    final List<CarDocument> reminders = [];
    final List<CarDocument> dueSoon = [];

    for (final CarDocument document in _carDocuments) {
      final int daysUntil =
      CarDocumentReminderService.daysUntilExpiry(
        document.expiryDate,
      );

      if (daysUntil < 0) {
        overdue.add(document);
      } else if (daysUntil == 0) {
        dueToday.add(document);
      } else if (CarDocumentReminderService.isReminderDue(
        document.expiryDate,
      )) {
        reminders.add(document);
      } else if (daysUntil <= 30) {
        dueSoon.add(document);
      }
    }

    final int activeAlertCount =
        overdue.length + dueToday.length + reminders.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Car Document Expiry Alerts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (activeAlertCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$activeAlertCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDocumentAlertSummary(
          overdueCount: overdue.length,
          dueTodayCount: dueToday.length,
          reminderCount: reminders.length,
          dueSoonCount: dueSoon.length,
        ),
        const SizedBox(height: 20),
        if (activeAlertCount == 0 && dueSoon.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 52,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active Car Document reminders',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'There are currently no Car Document expiry alerts.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        if (overdue.isNotEmpty)
          _buildDocumentAlertGroup(
            title: 'Expired',
            icon: Icons.warning_amber_rounded,
            status: 'Expired',
            documents: overdue,
          ),
        if (dueToday.isNotEmpty)
          _buildDocumentAlertGroup(
            title: 'Expires Today',
            icon: Icons.today,
            status: 'Due Today',
            documents: dueToday,
          ),
        if (reminders.isNotEmpty)
          _buildDocumentAlertGroup(
            title: 'Expiry Reminders Due',
            icon: Icons.notifications_active,
            status: 'Reminder Due',
            documents: reminders,
          ),
        if (dueSoon.isNotEmpty)
          _buildDocumentAlertGroup(
            title: 'Expiring Soon',
            icon: Icons.event_available,
            status: 'Due Soon',
            documents: dueSoon,
          ),
      ],
    );
  }

  Widget _buildDocumentAlertSummary({
    required int overdueCount,
    required int dueTodayCount,
    required int reminderCount,
    required int dueSoonCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Expired',
                count: overdueCount,
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'Due Today',
                count: dueTodayCount,
                icon: Icons.today,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Reminders',
                count: reminderCount,
                icon: Icons.notifications_active,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'Due Soon',
                count: dueSoonCount,
                icon: Icons.event_available,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentAlertGroup({
    required String title,
    required IconData icon,
    required String status,
    required List<CarDocument> documents,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text('(${documents.length})'),
            ],
          ),
          const SizedBox(height: 8),
          ...documents.map(
                (CarDocument document) => _buildDocumentAlertCard(
              document: document,
              status: status,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentAlertCard({
    required CarDocument document,
    required String status,
  }) {
    final int daysUntil =
    CarDocumentReminderService.daysUntilExpiry(
      document.expiryDate,
    );
    final String formattedDate =
    DateFormat('dd/MM/yyyy').format(document.expiryDate);

    final bool canSendSms =
    CarDocumentReminderService.hasActiveReminder(
      document.expiryDate,
    );

    Color statusColor;

    if (status == 'Expired') {
      statusColor = Colors.red;
    } else if (status == 'Due Today') {
      statusColor = Colors.orange;
    } else if (status == 'Reminder Due') {
      statusColor = Colors.deepOrange;
    } else {
      statusColor = Colors.blue;
    }

    final String remainingText;

    if (daysUntil < 0) {
      final int overdueDays = daysUntil.abs();
      remainingText =
      '$overdueDays day${overdueDays == 1 ? '' : 's'} expired';
    } else if (daysUntil == 0) {
      remainingText = 'Expires today';
    } else {
      remainingText =
      '$daysUntil day${daysUntil == 1 ? '' : 's'} remaining';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.documentType,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.customerName.trim().isEmpty
                        ? 'Customer Name Not Available'
                        : document.customerName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.customerNumber.trim().isEmpty
                        ? 'Customer Number Not Available'
                        : document.customerNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.directions_car_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document.vehicleNumber.trim().isEmpty
                        ? 'Vehicle Number Not Available'
                        : document.vehicleNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_available, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Expiry Date: $formattedDate'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  daysUntil <= 0
                      ? Icons.warning_amber_rounded
                      : Icons.schedule,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  remainingText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (canSendSms && document.id != null) ...[
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _isCarDocumentReminderAlreadySent(document),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 44,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (snapshot.data == true) {
                    return _buildSmsSentLabel();
                  }

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final bool opened =
                        await _sendCarDocumentExpirySms(document);
                        if (!opened || !mounted || document.id == null) return;

                        final int reminderDay =
                        _getCarDocumentReminderDay(document.expiryDate);

                        await SmsReminderTrackerService
                            .markCarDocumentReminderSent(
                          recordId: document.id!,
                          reminderDay: reminderDay,
                        );

                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.sms_outlined),
                      label: const Text('Send Expiry Reminder SMS'),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _getFleetReminderDay(DateTime nextServiceDate) {
    final int daysUntil =
    FleetServiceReminderService.daysUntilService(nextServiceDate);

    return FleetServiceReminderService.getReminderDays(nextServiceDate) ??
        (daysUntil == 0 ? 0 : -1);
  }

  Future<bool> _isFleetReminderAlreadySent(
      FleetService service,
      DateTime nextServiceDate,
      ) async {
    if (service.id == null) return false;

    return SmsReminderTrackerService.isFleetReminderSent(
      recordId: service.id!,
      reminderDay: _getFleetReminderDay(nextServiceDate),
    );
  }

  int _getCarDocumentReminderDay(DateTime expiryDate) {
    final int daysUntil =
    CarDocumentReminderService.daysUntilExpiry(expiryDate);

    return CarDocumentReminderService.getReminderDays(expiryDate) ??
        (daysUntil == 0 ? 0 : -1);
  }

  Future<bool> _isCarDocumentReminderAlreadySent(
      CarDocument document,
      ) async {
    if (document.id == null) return false;

    return SmsReminderTrackerService.isCarDocumentReminderSent(
      recordId: document.id!,
      reminderDay: _getCarDocumentReminderDay(document.expiryDate),
    );
  }

  Widget _buildSmsSentLabel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green),
          SizedBox(width: 8),
          Text(
            'Reminder SMS Opened',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _sendCarDocumentExpirySms(
      CarDocument document,
      ) async {
    final String customerNumber = document.customerNumber.trim();

    if (customerNumber.isEmpty) {
      _showDashboardMessage(
        'Customer number is not available.',
        isError: true,
      );
      return false;
    }

    final String formattedDate =
    DateFormat('dd/MM/yyyy').format(document.expiryDate);

    final String message = '''
Dear Customer,

This is a reminder from Sri Guru Enterprises.

Your ${document.documentType} for vehicle ${document.vehicleNumber} is due to expire on $formattedDate.

Kindly renew the document before the expiry date.

Thank you,
Sri Guru Enterprises
For any queries please contact 9148763008
''';

    try {
      final bool opened = await SmsService.openSms(
        phoneNumber: customerNumber,
        message: message.trim(),
      );

      if (!opened) {
        if (mounted) {
          _showDashboardMessage(
            'Unable to open the SMS application.',
            isError: true,
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      if (!mounted) return false;
      _showDashboardMessage(
        'Unable to open SMS.',
        isError: true,
      );
      return false;
    }
  }

  // ============================================================
  // NO ACTIVE ALERTS
  // ============================================================

  Widget _buildNoActiveAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 52,
            ),

            const SizedBox(height: 12),

            Text(
              'No active Fleet Service reminders',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            const Text(
              'There are currently no overdue, due today or scheduled Fleet Service reminders.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEND FLEET SERVICE REMINDER SMS
  //
  // SMS is opened directly from Dashboard.
  //
  // The normal SMS application receives:
  //
  // - Customer Number
  // - Pre-filled reminder message
  //
  // The user presses Send manually.
  // ============================================================

  Future<bool> _sendFleetServiceReminderSms(
      FleetService service,
      ) async {
    // ----------------------------------------------------------
    // CALCULATE NEXT SERVICE DATE
    // ----------------------------------------------------------

    final DateTime nextServiceDate =
    FleetServiceReminderService
        .calculateNextServiceDate(
      service.date,
    );

    // ----------------------------------------------------------
    // CUSTOMER NUMBER
    // ----------------------------------------------------------

    final String customerNumber =
    service.customerNumber.trim();

    if (customerNumber.isEmpty) {
      _showDashboardMessage(
        'Customer number is not available.',
        isError: true,
      );

      return false;
    }

    // ----------------------------------------------------------
    // FORMAT DATE
    // ----------------------------------------------------------

    final String formattedDate =
    DateFormat('dd/MM/yyyy')
        .format(nextServiceDate);

    // ----------------------------------------------------------
    // SMS MESSAGE
    // ----------------------------------------------------------

    final String message = '''
Dear Customer,

This is a reminder from Sri Guru Enterprises.

Your vehicle ${service.vehicleNumber} is due for its next Fleet Service on $formattedDate.

Kindly bring your vehicle for service to keep it in good condition.

Thank you,
Sri Guru Enterprises
For any queries please contact 9148763008
''';

    // ----------------------------------------------------------
    // OPEN SMS APPLICATION
    // ----------------------------------------------------------

    try {
      final bool opened =
      await SmsService.openSms(
        phoneNumber: customerNumber,
        message: message.trim(),
      );

      if (!opened) {
        if (mounted) {
          _showDashboardMessage(
            'Unable to open the SMS application.',
            isError: true,
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      if (!mounted) return false;

      _showDashboardMessage(
        'Unable to open SMS.',
        isError: true,
      );
      return false;
    }
  }

  // ============================================================
  // SHOW DASHBOARD MESSAGE
  // ============================================================

  void _showDashboardMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),

          backgroundColor:
          isError ? Colors.red : null,
        ),
      );
  }
}
