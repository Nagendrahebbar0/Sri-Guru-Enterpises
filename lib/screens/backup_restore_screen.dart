// ============================================================
// FILE: backup_restore_screen.dart
//
// PURPOSE:
// Provides the Backup & Restore user interface.
//
// FEATURES:
// - Google Sign-In
// - Google account information
// - Manual Backup Now
// - Restore Latest Backup
// - Select Backup
// - Automatic Backup ON/OFF
// - Last automatic backup information
// - Google Drive backup list
// - Restore confirmation
// - Status messages
//
// IMPORTANT:
// - Firebase is NOT used.
// - Google Drive is used for cloud backup.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../backup/auth/google_auth_service.dart';
import '../backup/managers/backup_manager.dart';
import '../backup/providers/google_drive_provider.dart';
import '../backup/services/auto_backup_service.dart';
import '../backup/services/restore_service.dart';

// ============================================================
// BACKUP & RESTORE SCREEN
// ============================================================

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
  });

  @override
  State<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

// ============================================================
// STATE
// ============================================================

class _BackupRestoreScreenState
    extends State<BackupRestoreScreen> {
  // ----------------------------------------------------------
  // MANAGER
  // ----------------------------------------------------------

  final BackupManager _backupManager =
      BackupManager.instance;

  // ----------------------------------------------------------
  // STATE
  // ----------------------------------------------------------

  bool _isLoading = true;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  bool _autoBackupEnabled = true;

  String? _lastAutoBackupDate;

  List<GoogleDriveBackupFile> _backups =
  <GoogleDriveBackupFile>[];

  String? _statusMessage;

  bool _statusIsError = false;

  // ----------------------------------------------------------
  // DATE FORMAT
  // ----------------------------------------------------------

  final DateFormat _dateTimeFormat =
  DateFormat('dd/MM/yyyy at hh:mm a');

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadInitialState();
  }

  // ==========================================================
  // LOAD INITIAL STATE
  // ==========================================================

  Future<void> _loadInitialState() async {
    try {
      _autoBackupEnabled =
      await AutoBackupService.isEnabled();

      _lastAutoBackupDate =
      await AutoBackupService.lastBackupDate();

      if (GoogleAuthService.isSignedIn) {
        await _loadCloudBackups();
      }
    } catch (_) {
      _setStatus(
        'Unable to load backup information.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // LOAD CLOUD BACKUPS
  // ==========================================================

  Future<void> _loadCloudBackups() async {
    try {
      final List<GoogleDriveBackupFile> backups =
      await _backupManager.getAvailableBackups();

      if (!mounted) {
        return;
      }

      setState(() {
        _backups = backups;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _setStatus(
        'Unable to load Google Drive backups.',
        isError: true,
      );
    }
  }

  // ==========================================================
  // GOOGLE SIGN-IN
  // ==========================================================

  Future<void> _signIn() async {
    _clearStatus();

    final GoogleSignInAccount? account =
    await GoogleAuthService.signIn();

    if (!mounted) {
      return;
    }

    if (account == null) {
      _setStatus(
        'Google Sign-In was cancelled or failed.',
        isError: true,
      );

      return;
    }

    setState(() {});

    await _loadCloudBackups();

    if (!mounted) {
      return;
    }

    _setStatus(
      'Signed in as ${account.email}.',
    );
  }

  // ==========================================================
  // GOOGLE SIGN-OUT
  // ==========================================================

  Future<void> _signOut() async {
    _clearStatus();

    await GoogleAuthService.signOut();

    if (!mounted) {
      return;
    }

    setState(() {
      _backups = <GoogleDriveBackupFile>[];
    });

    _setStatus(
      'Google account signed out.',
    );
  }

  // ==========================================================
  // MANUAL BACKUP
  // ==========================================================

  Future<void> _backupNow() async {
    _clearStatus();

    if (!GoogleAuthService.isSignedIn) {
      _setStatus(
        'Please sign in with Google before creating a backup.',
        isError: true,
      );

      return;
    }

    setState(() {
      _isBackingUp = true;
    });

    try {
      final GoogleDriveBackupFile? backup =
      await _backupManager.backupNow();

      if (!mounted) {
        return;
      }

      if (backup == null) {
        _setStatus(
          'Backup could not be completed.',
          isError: true,
        );

        return;
      }

      await _loadCloudBackups();

      if (!mounted) {
        return;
      }

      _setStatus(
        'Backup completed successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _setStatus(
        'Backup failed: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  // ==========================================================
  // RESTORE LATEST BACKUP
  // ==========================================================

  Future<void> _restoreLatestBackup() async {
    _clearStatus();

    if (!GoogleAuthService.isSignedIn) {
      _setStatus(
        'Please sign in with Google before restoring a backup.',
        isError: true,
      );

      return;
    }

    await _loadCloudBackups();

    if (!mounted) {
      return;
    }

    if (_backups.isEmpty) {
      _setStatus(
        'No Google Drive backup is available.',
        isError: true,
      );

      return;
    }

    final GoogleDriveBackupFile latest =
        _backups.first;

    final bool confirmed =
    await _showRestoreConfirmation(
      latest,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _performRestore(
      latest,
    );
  }

  // ==========================================================
  // SELECT BACKUP
  // ==========================================================

  Future<void> _selectBackupAndRestore() async {
    _clearStatus();

    if (!GoogleAuthService.isSignedIn) {
      _setStatus(
        'Please sign in with Google before restoring a backup.',
        isError: true,
      );

      return;
    }

    await _loadCloudBackups();

    if (!mounted) {
      return;
    }

    if (_backups.isEmpty) {
      _setStatus(
        'No Google Drive backup is available.',
        isError: true,
      );

      return;
    }

    final GoogleDriveBackupFile? selected =
    await showModalBottomSheet<
        GoogleDriveBackupFile>(
      context: context,
      showDragHandle: true,
      builder: (
          BuildContext context,
          ) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(
              bottom: 16,
            ),
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  12,
                ),
                child: Text(
                  'Select Backup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ..._backups.map(
                    (
                    GoogleDriveBackupFile backup,
                    ) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(
                        Icons.backup_outlined,
                      ),
                    ),
                    title: Text(
                      backup.name,
                    ),
                    subtitle: Text(
                      _formatBackupDate(
                        backup.createdTime,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
                      Navigator.of(context).pop(
                        backup,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    final bool confirmed =
    await _showRestoreConfirmation(
      selected,
    );

    if (!confirmed || !mounted) {
      return;
    }

    await _performRestore(
      selected,
    );
  }

  // ==========================================================
  // PERFORM RESTORE
  // ==========================================================

  Future<void> _performRestore(
      GoogleDriveBackupFile backup,
      ) async {
    _clearStatus();

    setState(() {
      _isRestoring = true;
    });

    try {
      final RestoreResult result =
      await _backupManager.restoreBackup(
        backup: backup,
      );

      if (!mounted) {
        return;
      }

      _setStatus(
        result.message,
        isError: !result.success,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _setStatus(
        'Restore failed: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  // ==========================================================
  // RESTORE CONFIRMATION
  // ==========================================================

  Future<bool> _showRestoreConfirmation(
      GoogleDriveBackupFile backup,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext context,
          ) {
        return AlertDialog(
          title: const Text(
            'Restore Backup?',
          ),
          content: Text(
            'Restore this backup?\n\n'
                '${backup.name}\n\n'
                'A safety copy of the current database '
                'will be created before restoration.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  true,
                );
              },
              child: const Text(
                'Restore',
              ),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  // ==========================================================
  // AUTO BACKUP TOGGLE
  // ==========================================================

  Future<void> _setAutoBackup(
      bool enabled,
      ) async {
    await AutoBackupService.setEnabled(
      enabled,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _autoBackupEnabled = enabled;
    });

    _setStatus(
      enabled
          ? 'Automatic backup enabled.'
          : 'Automatic backup disabled.',
    );
  }

  // ==========================================================
  // STATUS
  // ==========================================================

  void _setStatus(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = message;
      _statusIsError = isError;
    });
  }

  void _clearStatus() {
    if (!mounted) {
      return;
    }

    setState(() {
      _statusMessage = null;
      _statusIsError = false;
    });
  }

  // ==========================================================
  // FORMAT BACKUP DATE
  // ==========================================================

  String _formatBackupDate(
      DateTime? date,
      ) {
    if (date == null) {
      return 'Date unavailable';
    }

    return _dateTimeFormat.format(
      date.toLocal(),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Backup & Restore',
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildStatusCard(),
            _buildGoogleAccountCard(),
            const SizedBox(height: 16),
            _buildBackupCard(),
            const SizedBox(height: 16),
            _buildRestoreCard(),
            const SizedBox(height: 16),
            _buildAutoBackupCard(),
            const SizedBox(height: 16),
            _buildBackupListCard(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // STATUS CARD
  // ==========================================================

  Widget _buildStatusCard() {
    if (_statusMessage == null) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme =
        Theme.of(context).colorScheme;

    return Card(
      color: _statusIsError
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              _statusIsError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: _statusIsError
                  ? colorScheme.onErrorContainer
                  : colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusIsError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // GOOGLE ACCOUNT CARD
  // ==========================================================

  Widget _buildGoogleAccountCard() {
    final bool signedIn =
        GoogleAuthService.isSignedIn;

    final String? email =
        GoogleAuthService.email;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.account_circle_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'Google Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (signedIn) ...<Widget>[
              Text(
                email ?? 'Google account',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Sign Out',
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: _signIn,
                icon: const Icon(
                  Icons.login,
                ),
                label: const Text(
                  'Sign in with Google',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BACKUP CARD
  // ==========================================================

  Widget _buildBackupCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_upload_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a backup of all Sri Guru Enterprises '
                  'data and upload it to Google Drive.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                (_isBackingUp || _isRestoring)
                    ? null
                    : _backupNow,
                icon: _isBackingUp
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.backup,
                ),
                label: Text(
                  _isBackingUp
                      ? 'Creating Backup...'
                      : 'Backup Now',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RESTORE CARD
  // ==========================================================

  Widget _buildRestoreCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_download_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'Restore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Restore your application data from a '
                  'Google Drive backup.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                (_isBackingUp || _isRestoring)
                    ? null
                    : _restoreLatestBackup,
                icon: _isRestoring
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.restore,
                ),
                label: Text(
                  _isRestoring
                      ? 'Restoring...'
                      : 'Restore Latest Backup',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                (_isBackingUp || _isRestoring)
                    ? null
                    : _selectBackupAndRestore,
                icon: const Icon(
                  Icons.folder_open_outlined,
                ),
                label: const Text(
                  'Select Backup',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // AUTO BACKUP CARD
  // ==========================================================

  Widget _buildAutoBackupCard() {
    return Card(
      child: SwitchListTile(
        value: _autoBackupEnabled,
        onChanged: _setAutoBackup,
        title: const Text(
          'Automatic Backup',
        ),
        subtitle: Text(
          _lastAutoBackupDate == null
              ? 'Runs automatically when the app starts.'
              : 'Last automatic backup: '
              '$_lastAutoBackupDate',
        ),
        secondary: const Icon(
          Icons.schedule_outlined,
        ),
      ),
    );
  }

  // ==========================================================
  // BACKUP LIST CARD
  // ==========================================================

  Widget _buildBackupListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.cloud_outlined,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Google Drive Backups',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed:
                  GoogleAuthService.isSignedIn
                      ? _loadCloudBackups
                      : null,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!GoogleAuthService.isSignedIn)
              const Text(
                'Sign in with Google to view your backups.',
              )
            else if (_backups.isEmpty)
              const Text(
                'No backups found.',
              )
            else
              ..._backups.map(
                    (
                    GoogleDriveBackupFile backup,
                    ) {
                  return ListTile(
                    contentPadding:
                    EdgeInsets.zero,
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
                    ),
                    title: Text(
                      backup.name,
                    ),
                    subtitle: Text(
                      _formatBackupDate(
                        backup.createdTime,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // REFRESH
  // ==========================================================

  Future<void> _refresh() async {
    await _loadInitialState();
  }
}