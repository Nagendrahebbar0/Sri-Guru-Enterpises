// ============================================================
// FILE: main.dart
//
// PURPOSE:
// Entry point of the Sri Guru Enterprises Flutter application.
//
// FUNCTIONALITY:
// - Initializes Flutter.
// - Starts the Sri Guru Enterprises application.
// ============================================================

import 'package:flutter/material.dart';

import 'app/app.dart';

// ============================================================
// MAIN FUNCTION
//
// Flutter begins execution from this function.
// ============================================================

void main() {
  // ------------------------------------------------------------
  // INITIALIZE FLUTTER
  //
  // Ensures Flutter's framework is initialized before the
  // application starts.
  // ------------------------------------------------------------

  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // START APPLICATION
  //
  // Loads the root Sri Guru Enterprises application widget.
  // ------------------------------------------------------------

  runApp(
    const SriGuruEnterprisesApp(),
  );
}