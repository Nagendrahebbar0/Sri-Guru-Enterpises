// ============================================================
// FILE: main.dart
//
// PURPOSE:
// Entry point of the Sri Guru Enterprises Flutter application.
//
// FUNCTIONALITY:
// - Initializes Flutter.
// - Initializes Google Sign-In.
// - Restores the previous Google session.
// - Starts the application.
// - Starts the daily automatic Google Drive backup check.
//
// IMPORTANT:
// - Automatic backup must never prevent the application from
//   starting.
// - Automatic backup runs in the background after runApp().
// - Firebase is NOT used.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'backup/auth/google_auth_service.dart';
import 'backup/services/auto_backup_service.dart';

// ============================================================
// MAIN FUNCTION
//
// Flutter begins execution from this function.
// ============================================================

Future<void> main() async {
  // ------------------------------------------------------------
  // INITIALIZE FLUTTER
  //
  // Required before performing asynchronous initialization.
  // ------------------------------------------------------------

  WidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------
  // INITIALIZE GOOGLE SIGN-IN
  //
  // This prepares Google authentication before the application
  // starts.
  // ------------------------------------------------------------

  try {
    await GoogleAuthService.initialize();
  } catch (e) {
    // ----------------------------------------------------------
    // Google initialization failure must not stop the app.
    // ----------------------------------------------------------

    debugPrint(
      'Google Sign-In initialization failed: $e',
    );
  }

  // ------------------------------------------------------------
  // RESTORE PREVIOUS GOOGLE SESSION
  //
  // If the user previously signed in, restore that session.
  // ------------------------------------------------------------

  try {
    await GoogleAuthService.restoreSession();
  } catch (e) {
    // ----------------------------------------------------------
    // Session restoration failure must not stop the app.
    // ----------------------------------------------------------

    debugPrint(
      'Google session restoration failed: $e',
    );
  }

  // ------------------------------------------------------------
  // START APPLICATION
  //
  // The application starts without waiting for the backup
  // operation.
  // ------------------------------------------------------------

  runApp(
    const SriGuruEnterprisesApp(),
  );

  // ------------------------------------------------------------
  // DAILY AUTOMATIC BACKUP
  //
  // Run after the application has started.
  //
  // unawaited() ensures that Google Drive/network operations
  // never block the application startup.
  // ------------------------------------------------------------

  unawaited(
    _runAutomaticBackup(),
  );
}

// ============================================================
// AUTOMATIC BACKUP
// ============================================================

Future<void> _runAutomaticBackup() async {
  try {
    // ----------------------------------------------------------
    // checkAndBackup() is responsible for:
    //
    // - Checking whether today's backup already exists.
    // - Creating a backup when required.
    // - Uploading it to Google Drive.
    // - Recording the successful backup date.
    // - Doing nothing if today's backup already exists.
    // ----------------------------------------------------------

    await AutoBackupService.checkAndBackup();
  } catch (e) {
    // ----------------------------------------------------------
    // Automatic backup must NEVER crash the application.
    // ----------------------------------------------------------

    debugPrint(
      'Automatic backup failed: $e',
    );
  }
}