// ============================================================
// FILE: backup_restore_screen.dart
//
// PURPOSE:
// Provides the user interface for Google Drive backup and
// restore of the complete Sri Guru Enterprises database.
//
// FEATURES:
// - Google account sign-in/sign-out.
// - Create complete SQLite database backup.
// - Upload backup to Google Drive.
// - Display available Google Drive backups.
// - Restore a selected backup.
// - Restore the latest backup.
// - Delete a selected backup.
// - Refresh backup list.
//
// IMPORTANT:
// - Uses the new BackupManager.
// - Does NOT use the old BackupFile JSON system.
// - Does NOT create customer-only backups.
// - Does NOT change the application's bottom navigation.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backup/services/restore_service.dart';

import '../backup/auth/google_auth_service.dart';
import '../backup/managers/backup_manager.dart';
import '../backup/providers/google_drive_provider.dart';

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
// SCREEN STATE
// ============================================================

class _BackupRestoreScreenState
    extends State<BackupRestoreScreen> {
  // ----------------------------------------------------------
  // PROCESSING STATE
  // ----------------------------------------------------------

  bool _isProcessing = false;

  // ----------------------------------------------------------
  // GOOGLE ACCOUNT STATE
  // ----------------------------------------------------------

  bool _isSignedIn = false;

  String _userName = '';

  String _email = '';

  // ----------------------------------------------------------
  // GOOGLE DRIVE BACKUPS
  // ----------------------------------------------------------

  List<GoogleDriveBackupFile> _backups =
  <GoogleDriveBackupFile>[];

  // ----------------------------------------------------------
  // INITIALIZATION STATE
  // ----------------------------------------------------------

  bool _isLoadingBackups = false;

  // ----------------------------------------------------------
  // DATE FORMAT
  // ----------------------------------------------------------

  final DateFormat _dateFormat =
  DateFormat('dd/MM/yyyy hh:mm a');

  // ==========================================================
  // INIT STATE
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  // ==========================================================
  // INITIALIZE SCREEN
  // ==========================================================

  Future<void> _initialize() async {
    // --------------------------------------------------------
    // Try to restore an existing Google session.
    // --------------------------------------------------------

    await GoogleAuthService.restoreSession();

    if (!mounted) {
      return;
    }

    _refreshGoogleAccount();

    // --------------------------------------------------------
    // Load backups only when a Google account is available.
    // --------------------------------------------------------

    if (_isSignedIn) {
      await _loadBackups();
    }
  }

  // ==========================================================
  // REFRESH GOOGLE ACCOUNT INFORMATION
  // ==========================================================

  void _refreshGoogleAccount() {
    if (!mounted) {
      return;
    }

    setState(() {
      _isSignedIn =
          GoogleAuthService.isSignedIn;

      _userName =
          GoogleAuthService.displayName ?? '';

      _email =
          GoogleAuthService.email ?? '';
    });
  }

  // ==========================================================
  // GOOGLE SIGN-IN
  // ==========================================================

  Future<void> _signIn() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ------------------------------------------------------
      // Sign in to Google.
      // ------------------------------------------------------

      final account =
      await GoogleAuthService.signIn();

      if (!mounted) {
        return;
      }

      // ------------------------------------------------------
      // Update account information.
      // ------------------------------------------------------

      _refreshGoogleAccount();

      if (account == null) {
        _showMessage(
          'Google Sign-In was not completed.',
        );
        return;
      }

      // ------------------------------------------------------
      // Load Google Drive backups after successful sign-in.
      // ------------------------------------------------------

      await _loadBackups();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Google account signed in successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Google Sign-In failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // GOOGLE SIGN-OUT
  // ==========================================================

  Future<void> _signOut() async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await GoogleAuthService.signOut();

      if (!mounted) {
        return;
      }

      _refreshGoogleAccount();

      setState(() {
        _backups = <GoogleDriveBackupFile>[];
      });

      _showMessage(
        'Signed out successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to sign out: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // LOAD BACKUPS
  // ==========================================================

  Future<void> _loadBackups() async {
    if (!_isSignedIn) {
      return;
    }

    setState(() {
      _isLoadingBackups = true;
    });

    try {
      final List<GoogleDriveBackupFile> backups =
      await BackupManager.instance
          .getAvailableBackups();

      if (!mounted) {
        return;
      }

      setState(() {
        _backups = backups;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to load Google Drive backups: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBackups = false;
        });
      }
    }
  }

  // ==========================================================
  // BACKUP NOW
  // ==========================================================

  Future<void> _backupNow() async {
    if (!_isSignedIn || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // ------------------------------------------------------
      // Create and upload complete SQLite database.
      // ------------------------------------------------------

      final GoogleDriveBackupFile? backup =
      await BackupManager.instance.backupNow();

      if (!mounted) {
        return;
      }

      if (backup == null) {
        _showMessage(
          'Backup failed. Please check Google Drive access.',
        );
        return;
      }

      // ------------------------------------------------------
      // Refresh the displayed backup list.
      // ------------------------------------------------------

      await _loadBackups();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Database backup uploaded successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Backup failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // RESTORE LATEST BACKUP
  // ==========================================================

  Future<void> _restoreLatestBackup() async {
    if (!_isSignedIn ||
        _isProcessing ||
        _backups.isEmpty) {
      return;
    }

    // --------------------------------------------------------
    // Ask for confirmation because restore replaces the
    // current local database.
    // --------------------------------------------------------

    final bool confirmed =
    await _showRestoreConfirmation(
      title: 'Restore Latest Backup',
      message:
      'This will replace the current application database '
          'with the latest Google Drive backup.\n\n'
          'Your current database will first be protected with '
          'a safety copy.\n\n'
          'Continue?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final RestoreResult result =
      await BackupManager.instance
          .restoreLatestBackup();

      if (!mounted) {
        return;
      }

      if (result.success) {
        _showMessage(
          result.message,
        );

        // ----------------------------------------------------
        // Return to the previous screen so the application can
        // reload its data.
        // ----------------------------------------------------

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
      } else {
        _showMessage(
          result.message,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Restore failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // RESTORE SELECTED BACKUP
  // ==========================================================

  Future<void> _restoreBackup(
      GoogleDriveBackupFile backup,
      ) async {
    if (!_isSignedIn || _isProcessing) {
      return;
    }

    final bool confirmed =
    await _showRestoreConfirmation(
      title: 'Restore Backup',
      message:
      'This will replace the current application '
          'database with this backup:\n\n'
          '${backup.name}\n\n'
          'Your current database will first be protected '
          'with a safety copy.\n\n'
          'Continue?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final RestoreResult result =
      await BackupManager.instance.restoreBackup(
        backup: backup,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        _showMessage(
          result.message,
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pop(true);
      } else {
        _showMessage(
          result.message,
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Restore failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // DELETE BACKUP
  // ==========================================================

  Future<void> _deleteBackup(
      GoogleDriveBackupFile backup,
      ) async {
    if (!_isSignedIn || _isProcessing) {
      return;
    }

    // --------------------------------------------------------
    // Ask before permanently deleting a Drive backup.
    // --------------------------------------------------------

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Delete Backup',
          ),
          content: Text(
            'Delete this backup from Google Drive?\n\n'
                '${backup.name}',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final bool deleted =
      await BackupManager.instance.deleteBackup(
        backup: backup,
      );

      if (!mounted) {
        return;
      }

      if (deleted) {
        // ----------------------------------------------------
        // Remove the item immediately from the screen.
        // ----------------------------------------------------

        setState(() {
          _backups.removeWhere(
                (GoogleDriveBackupFile item) =>
            item.id == backup.id,
          );
        });

        _showMessage(
          'Backup deleted successfully.',
        );
      } else {
        _showMessage(
          'Unable to delete the backup.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Delete failed: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // ==========================================================
  // RESTORE CONFIRMATION
  // ==========================================================

  Future<bool> _showRestoreConfirmation({
    required String title,
    required String message,
  }) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: Text(
            title,
          ),
          content: Text(
            message,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              child: const Text(
                'Restore',
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  // ==========================================================
  // SHOW MESSAGE
  // ==========================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  // ==========================================================
  // FORMAT BACKUP DATE
  // ==========================================================

  String _formatBackupDate(
      DateTime? dateTime,
      ) {
    if (dateTime == null) {
      return 'Date unavailable';
    }

    return _dateFormat.format(
      dateTime.toLocal(),
    );
  }

  // ==========================================================
  // FORMAT FILE SIZE
  // ==========================================================

  String _formatFileSize(
      int? bytes,
      ) {
    if (bytes == null) {
      return 'Size unavailable';
    }

    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      final double kb =
          bytes / 1024;

      return '${kb.toStringAsFixed(1)} KB';
    }

    final double mb =
        bytes / (1024 * 1024);

    return '${mb.toStringAsFixed(2)} MB';
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
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed:
            _isProcessing || !_isSignedIn
                ? null
                : _loadBackups,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          RefreshIndicator(
            onRefresh: _isSignedIn
                ? _loadBackups
                : () async {},
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // ------------------------------------------------
                // GOOGLE ACCOUNT CARD
                // ------------------------------------------------

                _buildAccountCard(),

                const SizedBox(
                  height: 16,
                ),

                // ------------------------------------------------
                // BACKUP ACTION CARD
                // ------------------------------------------------

                _buildBackupActionCard(),

                const SizedBox(
                  height: 16,
                ),

                // ------------------------------------------------
                // BACKUP LIST
                // ------------------------------------------------

                _buildBackupList(),
              ],
            ),
          ),

          // ------------------------------------------------------
          // FULL SCREEN PROCESSING INDICATOR
          // ------------------------------------------------------

          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: <Widget>[
                        CircularProgressIndicator(),
                        SizedBox(
                          height: 16,
                        ),
                        Text(
                          'Please wait...',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // GOOGLE ACCOUNT CARD
  // ==========================================================

  Widget _buildAccountCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 24,
                  child: Icon(
                    _isSignedIn
                        ? Icons.account_circle
                        : Icons.person_outline,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Google Account',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        _isSignedIn
                            ? (_userName.isNotEmpty
                            ? _userName
                            : _email)
                            : 'Not signed in',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                      if (_isSignedIn &&
                          _email.isNotEmpty)
                        Text(
                          _email,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors
                                .grey
                                .shade700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              child: _isSignedIn
                  ? OutlinedButton.icon(
                onPressed:
                _isProcessing
                    ? null
                    : _signOut,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Sign Out',
                ),
              )
                  : FilledButton.icon(
                onPressed:
                _isProcessing
                    ? null
                    : _signIn,
                icon: const Icon(
                  Icons.login,
                ),
                label: const Text(
                  'Sign In with Google',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BACKUP ACTION CARD
  // ==========================================================

  Widget _buildBackupActionCard() {
    return Card(
      elevation: 2,
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
                SizedBox(
                  width: 10,
                ),
                Text(
                  'Database Backup',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Backup the complete Sri Guru Enterprises '
                  'SQLite database to Google Drive.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed:
                (!_isSignedIn ||
                    _isProcessing)
                    ? null
                    : _backupNow,
                icon: const Icon(
                  Icons.cloud_upload,
                ),
                label: const Text(
                  'Backup Now',
                ),
              ),
            ),

            if (_backups.isNotEmpty) ...<Widget>[
              const SizedBox(
                height: 10,
              ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed:
                  (!_isSignedIn ||
                      _isProcessing)
                      ? null
                      : _restoreLatestBackup,
                  icon: const Icon(
                    Icons.restore,
                  ),
                  label: const Text(
                    'Restore Latest Backup',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BACKUP LIST
  // ==========================================================

  Widget _buildBackupList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.cloud_done_outlined,
                ),
                const SizedBox(
                  width: 10,
                ),
                const Expanded(
                  child: Text(
                    'Google Drive Backups',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoadingBackups)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            if (!_isSignedIn)
              _buildEmptyState(
                icon: Icons.cloud_off_outlined,
                message:
                'Sign in with Google to view '
                    'your backups.',
              )
            else if (_isLoadingBackups &&
                _backups.isEmpty)
              const Padding(
                padding:
                EdgeInsets.symmetric(
                  vertical: 24,
                ),
                child: Center(
                  child:
                  CircularProgressIndicator(),
                ),
              )
            else if (_backups.isEmpty)
                _buildEmptyState(
                  icon: Icons.backup_outlined,
                  message:
                  'No database backups found '
                      'on Google Drive.',
                )
              else
                Column(
                  children: <Widget>[
                    // ----------------------------------------------
                    // Backup count
                    // ----------------------------------------------

                    Align(
                      alignment:
                      Alignment.centerLeft,
                      child: Text(
                        '${_backups.length} backup'
                            '${_backups.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color:
                          Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ----------------------------------------------
                    // Backup items
                    // ----------------------------------------------

                    ..._backups.map(
                          (
                          GoogleDriveBackupFile backup,
                          ) {
                        return _buildBackupTile(
                          backup,
                        );
                      },
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // BACKUP TILE
  // ==========================================================

  Widget _buildBackupTile(
      GoogleDriveBackupFile backup,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.storage_outlined,
                  size: 24,
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    backup.name,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _formatBackupDate(
                backup.createdTime,
              ),
              style: TextStyle(
                color:
                Colors.grey.shade700,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              _formatFileSize(
                backup.size,
              ),
              style: TextStyle(
                color:
                Colors.grey.shade700,
                fontSize: 13,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    _isProcessing
                        ? null
                        : () {
                      _restoreBackup(
                        backup,
                      );
                    },
                    icon: const Icon(
                      Icons.restore,
                      size: 18,
                    ),
                    label: const Text(
                      'Restore',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                IconButton(
                  tooltip: 'Delete backup',
                  onPressed:
                  _isProcessing
                      ? null
                      : () {
                    _deleteBackup(
                      backup,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 24,
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            size: 42,
            color: Colors.grey.shade500,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}