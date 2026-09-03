// ============================================================
// FILE: sms_service.dart
//
// PURPOSE:
// Opens the phone's normal SMS application.
//
// IMPORTANT:
// This service does NOT automatically send SMS.
//
// It opens the normal SMS application with:
// - Customer phone number
// - Pre-filled message
//
// The user will press the Send button manually.
// ============================================================

import 'package:url_launcher/url_launcher.dart';

class SmsService {
  // ------------------------------------------------------------
  // PRIVATE CONSTRUCTOR
  // ------------------------------------------------------------

  SmsService._();

  // ============================================================
  // OPEN SMS APPLICATION
  //
  // [phoneNumber]
  // Customer's mobile number.
  //
  // [message]
  // Message that should be pre-filled.
  //
  // Returns:
  // true  = SMS application opened successfully.
  // false = SMS application could not be opened.
  // ============================================================

  static Future<bool> openSms({
    required String phoneNumber,
    required String message,
  }) async {
    // ----------------------------------------------------------
    // CLEAN PHONE NUMBER
    // ----------------------------------------------------------

    final String cleanedPhoneNumber =
    phoneNumber.trim();

    // ----------------------------------------------------------
    // VALIDATE PHONE NUMBER
    // ----------------------------------------------------------

    if (cleanedPhoneNumber.isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // CREATE SMS URI
    // ----------------------------------------------------------

    final Uri smsUri = Uri(
      scheme: 'sms',
      path: cleanedPhoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    // ----------------------------------------------------------
    // CHECK WHETHER SMS APPLICATION IS AVAILABLE
    // ----------------------------------------------------------

    if (!await canLaunchUrl(smsUri)) {
      return false;
    }

    // ----------------------------------------------------------
    // OPEN SMS APPLICATION
    // ----------------------------------------------------------

    return launchUrl(smsUri);
  }
}