// ============================================================
// FILE: google_auth_service.dart
//
// PURPOSE:
// Handles Google account authentication for
// Sri Guru Enterprises.
//
// IMPORTANT:
// - Uses google_sign_in 7.2.0 API.
// - Uses Google Cloud OAuth directly.
// - Firebase is NOT used.
// - Google Drive authorization is requested separately.
// ============================================================

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  // ----------------------------------------------------------
  // GOOGLE SIGN-IN SINGLETON
  // ----------------------------------------------------------

  static final GoogleSignIn _googleSignIn =
      GoogleSignIn.instance;

  // ----------------------------------------------------------
  // WEB OAUTH CLIENT ID
  //
  // Replace this with the COMPLETE Web OAuth Client ID
  // created in Google Cloud Console.
  //
  // Do NOT use the Android OAuth Client ID here.
  // ----------------------------------------------------------

  static const String _serverClientId =
      '1073144691029-ec288sluil1oam76cjgl3c1603d5du7p.apps.googleusercontent.com';

  // ----------------------------------------------------------
  // INITIALIZATION STATE
  // ----------------------------------------------------------

  static bool _isInitialized = false;

  // ----------------------------------------------------------
  // CURRENT USER
  // ----------------------------------------------------------

  static GoogleSignInAccount? _currentUser;

  static GoogleSignInAccount? get currentUser {
    return _currentUser;
  }

  // ----------------------------------------------------------
  // GOOGLE DRIVE SCOPE
  //
  // We deliberately use the narrower drive.file permission.
  // ----------------------------------------------------------

  static const List<String> driveScopes = <String>[
    'https://www.googleapis.com/auth/drive.file',
  ];

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );

    _isInitialized = true;

    // --------------------------------------------------------
    // Listen for authentication state changes.
    // --------------------------------------------------------

    _googleSignIn.authenticationEvents.listen(
          (GoogleSignInAuthenticationEvent event) {
        if (event
        is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
        } else if (event
        is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
        }
      },
      onError: (Object error) {
        // Authentication errors should not crash the app.
      },
    );
  }

  // ==========================================================
  // RESTORE PREVIOUS SESSION
  // ==========================================================

  static Future<GoogleSignInAccount?>
  restoreSession() async {
    await _ensureInitialized();

    try {
      final GoogleSignInAccount? account =
      await _googleSignIn
          .attemptLightweightAuthentication(
        reportAllExceptions: false,
      );

      _currentUser = account;

      return account;
    } catch (_) {
      // App startup must not fail because Google Sign-In
      // restoration failed.
      return null;
    }
  }

  // ==========================================================
  // INTERACTIVE SIGN-IN
  // ==========================================================

  static Future<GoogleSignInAccount?> signIn() async {
    await _ensureInitialized();

    try {
      final GoogleSignInAccount account =
      await _googleSignIn.authenticate();

      _currentUser = account;

      return account;
    } on GoogleSignInException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // SIGN OUT
  // ==========================================================

  static Future<void> signOut() async {
    await _ensureInitialized();

    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Do not crash the application.
    }

    _currentUser = null;
  }

  // ==========================================================
  // DISCONNECT
  // ==========================================================

  static Future<void> disconnect() async {
    await _ensureInitialized();

    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Do not crash the application.
    }

    _currentUser = null;
  }

  // ==========================================================
  // GET DRIVE ACCESS TOKEN
  // ==========================================================

  static Future<String?> getDriveAccessToken({
    bool requestPermission = false,
  }) async {
    await _ensureInitialized();

    final GoogleSignInAccount? account =
        _currentUser;

    if (account == null) {
      return null;
    }

    try {
      GoogleSignInClientAuthorization?
      authorization;

      if (requestPermission) {
        authorization = await account
            .authorizationClient
            .authorizeScopes(
          driveScopes,
        );
      } else {
        authorization = await account
            .authorizationClient
            .authorizationForScopes(
          driveScopes,
        );
      }

      return authorization?.accessToken;
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // GET DRIVE AUTHORIZATION HEADERS
  // ==========================================================

  static Future<Map<String, String>?>
  getDriveAuthorizationHeaders({
    bool requestPermission = false,
  }) async {
    await _ensureInitialized();

    final GoogleSignInAccount? account =
        _currentUser;

    if (account == null) {
      return null;
    }

    try {
      if (requestPermission) {
        return await account
            .authorizationClient
            .authorizationHeaders(
          driveScopes,
          promptIfNecessary: true,
        );
      }

      return await account
          .authorizationClient
          .authorizationHeaders(
        driveScopes,
      );
    } catch (_) {
      return null;
    }
  }

  // ==========================================================
  // SIGN-IN STATUS
  // ==========================================================

  static bool get isSignedIn {
    return _currentUser != null;
  }

  // ==========================================================
  // ACCOUNT EMAIL
  // ==========================================================

  static String? get email {
    return _currentUser?.email;
  }

  // ==========================================================
  // DISPLAY NAME
  // ==========================================================

  static String? get displayName {
    return _currentUser?.displayName;
  }

  // ==========================================================
  // PHOTO URL
  // ==========================================================

  static String? get photoUrl {
    return _currentUser?.photoUrl;
  }

  // ==========================================================
  // ENSURE INITIALIZED
  // ==========================================================

  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }
}