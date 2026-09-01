// ============================================================
// FILE: app_theme.dart
//
// PURPOSE:
// Contains the common visual theme for the Sri Guru
// Enterprises application.
//
// FUNCTIONALITY:
// - Defines application colors.
// - Defines typography behavior.
// - Defines common input field styling.
// - Defines common button styling.
// - Defines common card styling.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// APP THEME
//
// Central location for the application's visual design.
// ============================================================

class AppTheme {
  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  //
  // Prevents this configuration class from being instantiated.
  // ------------------------------------------------------------

  AppTheme._();

  // ============================================================
  // LIGHT THEME
  //
  // Main theme used by the mobile application.
  // ============================================================

  static ThemeData lightTheme = ThemeData(
    // ----------------------------------------------------------
    // MATERIAL 3
    //
    // Enables Flutter's modern Material design components.
    // ----------------------------------------------------------

    useMaterial3: true,

    // ----------------------------------------------------------
    // COLOR SCHEME
    //
    // Sri Guru Enterprises will use a blue-based interface.
    // ----------------------------------------------------------

    colorSchemeSeed: Colors.blue,

    // ----------------------------------------------------------
    // APPLICATION BACKGROUND
    // ----------------------------------------------------------

    scaffoldBackgroundColor: const Color(0xFFF5F7FA),

    // ----------------------------------------------------------
    // APP BAR
    // ----------------------------------------------------------

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
    ),

    // ----------------------------------------------------------
    // INPUT FIELDS
    //
    // Used by forms such as:
    //
    // Customer
    // Vehicle
    // Fleet Service
    // Emission
    // Accessories
    // etc.
    // ----------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFE0E0E0),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.blue,
          width: 2,
        ),
      ),
    ),

    // ----------------------------------------------------------
    // BUTTONS
    // ----------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(
          120,
          48,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),

    // ----------------------------------------------------------
    // CARDS
    //
    // Cards will be used to display customers, vehicles and
    // service records.
    // ----------------------------------------------------------

    cardTheme: CardThemeData(
      elevation: 1,
      margin: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}