// ============================================================
// FILE: widget_test.dart
//
// PURPOSE:
// Tests the basic startup behavior of the Sri Guru
// Enterprises application.
//
// FUNCTIONALITY:
// - Starts the application.
// - Verifies that the main application interface appears.
// - Confirms that the application foundation is working.
// ============================================================

import 'package:flutter_test/flutter_test.dart';

import 'package:sri_guru_enterprise/app/app.dart';

// ============================================================
// MAIN TEST FUNCTION
// ============================================================

void main() {
  // ==========================================================
  // APPLICATION STARTUP TEST
  //
  // Verifies that the Sri Guru Enterprises application starts
  // correctly and displays the initial Dashboard content.
  // ==========================================================

  testWidgets(
    'Sri Guru Enterprises application starts successfully',
        (WidgetTester tester) async {
      // --------------------------------------------------------
      // START APPLICATION
      // --------------------------------------------------------

      await tester.pumpWidget(
        const SriGuruEnterprisesApp(),
      );

      // --------------------------------------------------------
      // ALLOW INITIAL WIDGET BUILDING
      //
      // pump() allows Flutter to complete the first frame.
      // --------------------------------------------------------

      await tester.pump();

      // --------------------------------------------------------
      // VERIFY APPLICATION NAME
      // --------------------------------------------------------

      expect(
        find.text('Sri Guru Enterprises'),
        findsWidgets,
      );

      // --------------------------------------------------------
      // VERIFY DASHBOARD FOUNDATION
      // --------------------------------------------------------

      expect(
        find.text('Sri Guru Enterprises'),
        findsOneWidget,
      );
    },
  );
}