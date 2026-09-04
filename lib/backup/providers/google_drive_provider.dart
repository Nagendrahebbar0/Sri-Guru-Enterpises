// ============================================================
// FILE: google_drive_provider.dart
//
// PURPOSE:
// Handles Google Drive operations for Sri Guru Enterprises.
//
// RESPONSIBILITIES:
// - Get Google Drive authorization.
// - Create/find the application backup folder.
// - Upload backup files.
// - List backup files.
// - Download backup files.
// - Delete backup files.
//
// IMPORTANT:
// - Uses Google Drive REST API.
// - Uses drive.file scope only.
// - Does NOT use Firebase.
// - Authentication is handled by GoogleAuthService.
// ============================================================

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../auth/google_auth_service.dart';

class GoogleDriveProvider {
  GoogleDriveProvider._();

  // ----------------------------------------------------------
  // SINGLETON
  // ----------------------------------------------------------

  static final GoogleDriveProvider instance = GoogleDriveProvider._();

  // ----------------------------------------------------------
  // GOOGLE DRIVE API
  // ----------------------------------------------------------

  static const String _driveApiBase =
      'https://www.googleapis.com/drive/v3';

  static const String _uploadApiBase =
      'https://www.googleapis.com/upload/drive/v3';

  // ----------------------------------------------------------
  // APPLICATION BACKUP FOLDER
  // ----------------------------------------------------------

  static const String backupFolderName = 'Sri Guru Enterprises';

  static const String _backupFolderMimeType =
      'application/vnd.google-apps.folder';

  // ----------------------------------------------------------
  // BACKUP FILE MIME TYPE
  //
  // SQLite database backup files will be uploaded as binary
  // files. The actual filename will identify the backup.
  // ----------------------------------------------------------

  static const String backupFileMimeType =
      'application/octet-stream';

  // ----------------------------------------------------------
  // CREATE / FIND BACKUP FOLDER
  //
  // drive.file allows the application to work with files and
  // folders created or opened through the application.
  // ----------------------------------------------------------

  Future<String?> getOrCreateBackupFolder() async {
    final headers =
    await GoogleAuthService.getDriveAuthorizationHeaders(
      requestPermission: true,
    );

    if (headers == null) {
      return null;
    }

    // --------------------------------------------------------
    // First try to find an existing folder created by the app.
    // --------------------------------------------------------

    final String escapedFolderName =
    backupFolderName.replaceAll("'", "\\'");

    final String query =
        "name = '$escapedFolderName' "
        "and mimeType = '$_backupFolderMimeType' "
        "and trashed = false";

    final Uri searchUri = Uri.parse(
      '$_driveApiBase/files'
          '?q=${Uri.encodeQueryComponent(query)}'
          '&spaces=drive'
          '&fields=files(id,name,mimeType)',
    );

    final http.Response searchResponse = await http.get(
      searchUri,
      headers: headers,
    );

    if (searchResponse.statusCode == 200) {
      final Map<String, dynamic> data =
      jsonDecode(searchResponse.body) as Map<String, dynamic>;

      final List<dynamic> files =
          data['files'] as List<dynamic>? ?? <dynamic>[];

      if (files.isNotEmpty) {
        final Map<String, dynamic> folder =
        files.first as Map<String, dynamic>;

        return folder['id'] as String?;
      }
    }

    // --------------------------------------------------------
    // Folder does not exist.
    // Create it.
    // --------------------------------------------------------

    final Uri createUri = Uri.parse(
      '$_driveApiBase/files'
          '?fields=id,name,mimeType',
    );

    final http.Response createResponse = await http.post(
      createUri,
      headers: <String, String>{
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'name': backupFolderName,
          'mimeType': _backupFolderMimeType,
        },
      ),
    );

    if (createResponse.statusCode == 200 ||
        createResponse.statusCode == 201) {
      final Map<String, dynamic> data =
      jsonDecode(createResponse.body) as Map<String, dynamic>;

      return data['id'] as String?;
    }

    throw GoogleDriveException(
      'Unable to create Google Drive backup folder.',
      statusCode: createResponse.statusCode,
      responseBody: createResponse.body,
    );
  }

  // ----------------------------------------------------------
  // UPLOAD BACKUP FILE
  //
  // The file is uploaded into the Sri Guru Enterprises folder.
  //
  // Returns the Google Drive file ID.
  // ----------------------------------------------------------

  Future<String?> uploadBackupFile({
    required File file,
    required String fileName,
  }) async {
    final headers =
    await GoogleAuthService.getDriveAuthorizationHeaders(
      requestPermission: true,
    );

    if (headers == null) {
      return null;
    }

    final String? folderId =
    await getOrCreateBackupFolder();

    if (folderId == null) {
      return null;
    }

    if (!await file.exists()) {
      throw GoogleDriveException(
        'Backup file does not exist.',
      );
    }

    final List<int> fileBytes =
    await file.readAsBytes();

    final String boundary =
        'sri_guru_drive_${DateTime.now().millisecondsSinceEpoch}';

    final List<int> metadataBytes =
    utf8.encode(
      jsonEncode(
        <String, dynamic>{
          'name': fileName,
          'parents': <String>[folderId],
          'mimeType': backupFileMimeType,
        },
      ),
    );

    final List<int> startBoundary =
    utf8.encode('--$boundary\r\n');

    final List<int> metadataPart =
    utf8.encode(
      'Content-Type: application/json; charset=UTF-8\r\n'
          '\r\n',
    );

    final List<int> mediaPart =
    utf8.encode(
      '\r\n'
          '--$boundary\r\n'
          'Content-Type: $backupFileMimeType\r\n'
          '\r\n',
    );

    final List<int> endBoundary =
    utf8.encode(
      '\r\n'
          '--$boundary--',
    );

    final List<int> body = <int>[
      ...startBoundary,
      ...metadataPart,
      ...metadataBytes,
      ...mediaPart,
      ...fileBytes,
      ...endBoundary,
    ];

    final Uri uploadUri = Uri.parse(
      '$_uploadApiBase/files'
          '?uploadType=multipart'
          '&fields=id,name,mimeType,size,createdTime',
    );

    final http.Response response = await http.post(
      uploadUri,
      headers: <String, String>{
        ...headers,
        'Content-Type':
        'multipart/related; boundary=$boundary',
        'Content-Length': body.length.toString(),
      },
      body: body,
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      final Map<String, dynamic> data =
      jsonDecode(response.body) as Map<String, dynamic>;

      return data['id'] as String?;
    }

    throw GoogleDriveException(
      'Unable to upload backup file.',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  // ----------------------------------------------------------
  // LIST BACKUP FILES
  //
  // Returns newest backups first.
  // ----------------------------------------------------------

  Future<List<GoogleDriveBackupFile>> listBackupFiles() async {
    final headers =
    await GoogleAuthService.getDriveAuthorizationHeaders(
      requestPermission: true,
    );

    if (headers == null) {
      return <GoogleDriveBackupFile>[];
    }

    final String? folderId =
    await getOrCreateBackupFolder();

    if (folderId == null) {
      return <GoogleDriveBackupFile>[];
    }

    final String query =
        "'$folderId' in parents "
        "and trashed = false";

    final Uri uri = Uri.parse(
      '$_driveApiBase/files'
          '?q=${Uri.encodeQueryComponent(query)}'
          '&spaces=drive'
          '&orderBy=createdTime desc'
          '&pageSize=100'
          '&fields=files(id,name,mimeType,size,createdTime)',
    );

    final http.Response response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw GoogleDriveException(
        'Unable to list Google Drive backups.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final Map<String, dynamic> data =
    jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> files =
        data['files'] as List<dynamic>? ?? <dynamic>[];

    return files
        .map(
          (dynamic item) =>
          GoogleDriveBackupFile.fromJson(
            item as Map<String, dynamic>,
          ),
    )
        .toList();
  }

  // ----------------------------------------------------------
  // DOWNLOAD BACKUP FILE
  //
  // Downloads the selected Google Drive backup and saves it
  // to the supplied local destination.
  // ----------------------------------------------------------

  Future<File?> downloadBackupFile({
    required String fileId,
    required File destinationFile,
  }) async {
    final headers =
    await GoogleAuthService.getDriveAuthorizationHeaders(
      requestPermission: true,
    );

    if (headers == null) {
      return null;
    }

    final Uri uri = Uri.parse(
      '$_driveApiBase/files/$fileId?alt=media',
    );

    final http.Response response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw GoogleDriveException(
        'Unable to download Google Drive backup.',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    await destinationFile.parent.create(
      recursive: true,
    );

    await destinationFile.writeAsBytes(
      response.bodyBytes,
      flush: true,
    );

    return destinationFile;
  }

  // ----------------------------------------------------------
  // DELETE BACKUP FILE
  //
  // Used later by backup-retention management.
  // ----------------------------------------------------------

  Future<bool> deleteBackupFile({
    required String fileId,
  }) async {
    final headers =
    await GoogleAuthService.getDriveAuthorizationHeaders(
      requestPermission: true,
    );

    if (headers == null) {
      return false;
    }

    final Uri uri = Uri.parse(
      '$_driveApiBase/files/$fileId',
    );

    final http.Response response =
    await http.delete(
      uri,
      headers: headers,
    );

    if (response.statusCode == 204 ||
        response.statusCode == 200) {
      return true;
    }

    throw GoogleDriveException(
      'Unable to delete Google Drive backup.',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }
}

// ============================================================
// GOOGLE DRIVE BACKUP FILE MODEL
// ============================================================

class GoogleDriveBackupFile {
  final String id;
  final String name;
  final String? mimeType;
  final int? size;
  final DateTime? createdTime;

  const GoogleDriveBackupFile({
    required this.id,
    required this.name,
    this.mimeType,
    this.size,
    this.createdTime,
  });

  factory GoogleDriveBackupFile.fromJson(
      Map<String, dynamic> json,
      ) {
    return GoogleDriveBackupFile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mimeType: json['mimeType'] as String?,
      size: _parseSize(json['size']),
      createdTime: _parseDateTime(
        json['createdTime'],
      ),
    );
  }

  static int? _parseSize(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime? _parseDateTime(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

// ============================================================
// GOOGLE DRIVE EXCEPTION
// ============================================================

class GoogleDriveException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  const GoogleDriveException(
      this.message, {
        this.statusCode,
        this.responseBody,
      });

  @override
  String toString() {
    if (statusCode == null) {
      return 'GoogleDriveException: $message';
    }

    return 'GoogleDriveException: $message '
        '(HTTP $statusCode)';
  }
}