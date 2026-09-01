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
// - Displays the Sri Guru Enterprises branding.
// - Connects the Customer Management module.
// - Connects the Fleet Services module.
// - Connects the Emission module.
//
// NAVIGATION:
//
// 0 → Dashboard
// 1 → Customers
// 2 → Fleet Services
// 3 → Emission
//
// IMPORTANT:
// This application is currently being developed specifically
// for mobile devices.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// APPLICATION SCREENS
// ============================================================

import '../screens/customer_list_screen.dart';
import '../screens/fleet_service_list_screen.dart';
import '../screens/emission_test_list_screen.dart';

// ============================================================
// APP SHELL
//
// Main container of the mobile application.
//
// The bottom NavigationBar allows the user to switch between
// Dashboard, Customers, Fleet Services and Emission.
// ============================================================

class AppShell extends StatefulWidget {
  // ------------------------------------------------------------
  // CONSTRUCTOR
  // ------------------------------------------------------------

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
  // ------------------------------------------------------------
  // CURRENT NAVIGATION INDEX
  //
  // 0 → Dashboard
  // 1 → Customers
  // 2 → Fleet Services
  // 3 → Emission
  // ------------------------------------------------------------

  int _currentIndex = 0;

  // ============================================================
  // BUILD METHOD
  //
  // Builds the main mobile application interface.
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ----------------------------------------------------------
      // MAIN CONTENT
      //
      // Displays the page corresponding to the selected
      // navigation destination.
      // ----------------------------------------------------------

      body: _buildCurrentPage(),

      // ----------------------------------------------------------
      // BOTTOM NAVIGATION
      //
      // Mobile-friendly navigation between the main sections.
      // ----------------------------------------------------------

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        // --------------------------------------------------------
        // NAVIGATION CHANGE
        //
        // Updates the currently selected application section.
        // --------------------------------------------------------

        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },

        // --------------------------------------------------------
        // NAVIGATION DESTINATIONS
        // --------------------------------------------------------

        destinations: const [
          // ======================================================
          // DASHBOARD
          // ======================================================

          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            selectedIcon: Icon(
              Icons.dashboard,
            ),
            label: 'Dashboard',
          ),

          // ======================================================
          // CUSTOMERS
          // ======================================================

          NavigationDestination(
            icon: Icon(
              Icons.people_outline,
            ),
            selectedIcon: Icon(
              Icons.people,
            ),
            label: 'Customers',
          ),

          // ======================================================
          // FLEET SERVICES
          // ======================================================

          NavigationDestination(
            icon: Icon(
              Icons.directions_car_outlined,
            ),
            selectedIcon: Icon(
              Icons.directions_car,
            ),
            label: 'Fleet',
          ),

          // ======================================================
          // EMISSION
          // ======================================================

          NavigationDestination(
            icon: Icon(
              Icons.air_outlined,
            ),
            selectedIcon: Icon(
              Icons.air,
            ),
            label: 'Emission',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD CURRENT PAGE
  //
  // Determines which page should be displayed based on the
  // selected navigation item.
  //
  // 0 → Dashboard
  // 1 → Customer Management
  // 2 → Fleet Services
  // 3 → Emission
  // ============================================================

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
    // ----------------------------------------------------------
    // DASHBOARD
    // ----------------------------------------------------------

      case 0:
        return _buildDashboard();

    // ----------------------------------------------------------
    // CUSTOMERS
    // ----------------------------------------------------------

      case 1:
        return const CustomerListScreen();

    // ----------------------------------------------------------
    // FLEET SERVICES
    // ----------------------------------------------------------

      case 2:
        return const FleetServiceListScreen();

    // ----------------------------------------------------------
    // EMISSION
    // ----------------------------------------------------------

      case 3:
        return const EmissionTestListScreen();

    // ----------------------------------------------------------
    // SAFETY FALLBACK
    // ----------------------------------------------------------

      default:
        return _buildDashboard();
    }
  }

  // ============================================================
  // DASHBOARD
  //
  // Temporary dashboard foundation.
  //
  // We will replace this with the real Dashboard later after
  // the core application modules are completed.
  // ============================================================

  Widget _buildDashboard() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ====================================================
            // APPLICATION LOGO
            // ====================================================

            Image.asset(
              'assets/icon/sri_guru_logo.png',
              width: 140,
              height: 140,
            ),

            const SizedBox(
              height: 24,
            ),

            // ====================================================
            // APPLICATION NAME
            // ====================================================

            Text(
              'Sri Guru Enterprises',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 8,
            ),

            // ====================================================
            // APPLICATION DESCRIPTION
            // ====================================================

            Text(
              'Fleet Services & Vehicle Services',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 32,
            ),

            // ====================================================
            // FOUNDATION MESSAGE
            //
            // Temporary message until the real Dashboard is
            // implemented.
            // ====================================================

            const Text(
              'Application foundation is ready',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}