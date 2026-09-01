// ============================================================
// FILE: app.dart
//
// PURPOSE:
// Defines the root application widget for Sri Guru
// Enterprises.
//
// FUNCTIONALITY:
// - Creates the MaterialApp.
// - Sets the application name.
// - Applies the application theme.
// - Opens the main application shell.
// ============================================================

import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'app_theme.dart';

// ============================================================
// SRI GURU ENTERPRISES APP
//
// This is the root widget of the entire application.
//
// All major application configuration starts from here.
// ============================================================

class SriGuruEnterprisesApp extends StatelessWidget {
  // ------------------------------------------------------------
  // CONSTRUCTOR
  //
  // Creates the root application widget.
  // ------------------------------------------------------------

  const SriGuruEnterprisesApp({
    super.key,
  });

  // ------------------------------------------------------------
  // BUILD METHOD
  //
  // Builds the MaterialApp used by Flutter.
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ----------------------------------------------------------
      // APPLICATION NAME
      //
      // This is the name used by Flutter internally and can also
      // be used by platform-specific configuration.
      // ----------------------------------------------------------

      title: 'Sri Guru Enterprises',

      // ----------------------------------------------------------
      // DEBUG BANNER
      //
      // Removes the "DEBUG" banner from the top-right corner
      // while running the application.
      // ----------------------------------------------------------

      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------
      // APPLICATION THEME
      //
      // All common visual styling is maintained inside
      // AppTheme.
      // ----------------------------------------------------------

      theme: AppTheme.lightTheme,

      // ----------------------------------------------------------
      // APPLICATION HOME
      //
      // AppShell contains the main mobile application interface
      // and navigation.
      // ----------------------------------------------------------

      home: const AppShell(),
    );
  }
}