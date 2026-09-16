import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';

import '../auth/google_auth_service.dart';

/// Represents one backup file stored in Google Drive.
class GoogleDriveBackupFile {
  const GoogleDriveBackupFile({
    required this.id,
    required this.name,
    this.createdTime,
    this.size,
  });

  /// Google Drive file ID.
  final String id;

  /// Backup file name.
  final String name;

  /// File creation time in Google Drive.
  final DateTime? createdTime;

  /// File size in bytes.
  final int? size;
}

/// Handles Google Drive operations for Sri Guru Enterprise backups.
///
/// This provider stores complete SQLite database backup files.
/// It does not store individual customer records or JSON files.
class GoogleDriveProvider {
  GoogleDriveProvider._();

  /// Singleton instance.
  static final GoogleDriveProvider instance = GoogleDriveProvider._();

  /// Name of the dedicated backup folder in Google Drive.
  static const String backupFolderName = 'SriGuruEnterprise_Backups';

  /// MIME type used by Google Drive for folders.
  static const String _folderMimeType = 'application/vnd.google-apps.folder';

  /// Creates a Google Drive API client using the currently signed-in
  /// Google account.
  /// Creates a Google Drive API client using the
  /// currently signed-in Google account.
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final AuthClient? client =
      await GoogleAuthService.getDriveAuthClient(
        requestPermission: true,
      );

      if (client == null) {
        return null;
      }

      return drive.DriveApi(client);
    } catch (_) {
      return null;
    }
  }

  /// Returns the backup folder ID.
  ///
  /// If the folder does not exist, it is created automatically.
  Future<String?> getBackupFolderId() async {
    final drive.DriveApi? driveApi = await _getDriveApi();

    if (driveApi == null) {
      return null;
    }

    try {
      // Search for our dedicated backup folder.
      final drive.FileList result = await driveApi.files.list(
        q: "name = '$backupFolderName' "
            "and mimeType = '$_folderMimeType' "
            "and trashed = false",
        spaces: 'drive',
        $fields: 'files(id,name)',
        pageSize: 10,
      );

      // Reuse the existing folder if it was found.
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }

      // Create the folder when it does not exist.
      final drive.File folder = drive.File()
        ..name = backupFolderName
        ..mimeType = _folderMimeType;

      final drive.File createdFolder = await driveApi.files.create(
        folder,
        $fields: 'id,name',
      );

      return createdFolder.id;
    } catch (e) {
      throw GoogleDriveBackupException(
        'Unable to access the Google Drive backup folder: $e',
      );
    }
  }

  /// Uploads a complete SQLite database backup to Google Drive.
  ///
  /// Returns the Google Drive file ID when successful.
  Future<String?> uploadBackupFile({
    required File file,
    required String fileName,
  }) async {
    if (!await file.exists()) {
      throw GoogleDriveBackupException(
        'The backup file does not exist.',
      );
    }

    final drive.DriveApi? driveApi = await _getDriveApi();

    if (driveApi == null) {
      return null;
    }

    final String? folderId = await getBackupFolderId();

    if (folderId == null) {
      throw GoogleDriveBackupException(
        'Unable to find or create the Google Drive backup folder.',
      );
    }

    try {
      // Create the Drive file metadata.
      final drive.File metadata = drive.File()
        ..name = fileName
        ..parents = <String>[folderId]
        ..mimeType = 'application/octet-stream';

      // Upload the complete SQLite database file.
      final drive.Media media = drive.Media(
        file.openRead(),
        await file.length(),
      );

      final drive.File uploadedFile = await driveApi.files.create(
        metadata,
        uploadMedia: media,
        $fields: 'id,name,createdTime,size',
      );

      return uploadedFile.id;
    } catch (e) {
      throw GoogleDriveBackupException(
        'Unable to upload the backup to Google Drive: $e',
      );
    }
  }

  /// Returns all Sri Guru Enterprise database backups stored in Drive.
  ///
  /// Newest backups are returned first.
  Future<List<GoogleDriveBackupFile>> listBackupFiles() async {
    final drive.DriveApi? driveApi = await _getDriveApi();

    if (driveApi == null) {
      return <GoogleDriveBackupFile>[];
    }

    final String? folderId = await getBackupFolderId();

    if (folderId == null) {
      return <GoogleDriveBackupFile>[];
    }

    try {
      final drive.FileList result = await driveApi.files.list(
        q: "'$folderId' in parents and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
        pageSize: 100,
        $fields: 'files(id,name,createdTime,size,mimeType)',
      );

      final List<GoogleDriveBackupFile> backups =
      <GoogleDriveBackupFile>[];

      for (final drive.File file in result.files ?? <drive.File>[]) {
        // Only show our SQLite database backup files.
        final String name = file.name ?? '';

        if (!name.toLowerCase().endsWith('.db')) {
          continue;
        }

        if (file.id == null || file.id!.isEmpty) {
          continue;
        }

        backups.add(
          GoogleDriveBackupFile(
            id: file.id!,
            name: name,
            createdTime: file.createdTime,
            size: file.size == null
                ? null
                : int.tryParse(file.size!),
          ),
        );
      }

      return backups;
    } catch (e) {
      throw GoogleDriveBackupException(
        'Unable to list Google Drive backups: $e',
      );
    }
  }

  /// Downloads a selected backup file from Google Drive.
  ///
  /// The downloaded database is written to [destinationFile].
  Future<File?> downloadBackupFile({
    required String fileId,
    required File destinationFile,
  }) async {
    final drive.DriveApi? driveApi = await _getDriveApi();

    if (driveApi == null) {
      return null;
    }

    try {
      // Ask Google Drive for the complete file contents.
      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Ensure the destination directory exists.
      await destinationFile.parent.create(
        recursive: true,
      );

      // Write the downloaded database to local storage.
      final IOSink output = destinationFile.openWrite();

      try {
        await media.stream.pipe(output);
      } finally {
        await output.close();
      }

      return destinationFile;
    } catch (e) {
      throw GoogleDriveBackupException(
        'Unable to download the backup from Google Drive: $e',
      );
    }
  }

  /// Deletes one backup file from Google Drive.
  Future<bool> deleteBackupFile({
    required String fileId,
  }) async {
    final drive.DriveApi? driveApi = await _getDriveApi();

    if (driveApi == null) {
      return false;
    }

    try {
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      throw GoogleDriveBackupException(
        'Unable to delete the Google Drive backup: $e',
      );
    }
  }
}

/// Exception thrown when a Google Drive backup operation fails.
class GoogleDriveBackupException implements Exception {
  GoogleDriveBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}