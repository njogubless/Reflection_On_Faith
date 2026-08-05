import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown for validation failures that happen before any network call, so
/// callers can show a message without it looking like a server/network
/// error.
class UploadValidationException implements Exception {
  final String message;
  const UploadValidationException(this.message);
  @override
  String toString() => message;
}

class UploadFiles {
  // Kept in sync with the size caps enforced in storage.rules — the client
  // check exists purely so a user gets an instant, friendly message instead
  // of waiting for the whole file to upload and then having Storage reject
  // it. The rules are the real enforcement; this is a courtesy.
  static const int maxAudioBytes = 100 * 1024 * 1024; // 100 MB
  static const int maxBookBytes = 50 * 1024 * 1024; // 50 MB

  /// Returns `true` if a file was picked and uploaded, `false` if the user
  /// cancelled the file picker (not an error — callers should treat this as
  /// a silent no-op, not a failure or a success).
  static Future<bool> uploadFileToFirebase(
      String collectionPath, String storagePath) async {
    FileType fileType = FileType.any;
    List<String>? allowedExtensions;
    int maxBytes = maxBookBytes;

    if (storagePath == 'audio') {
      fileType = FileType.audio;
      maxBytes = maxAudioBytes;
    } else if (storagePath == 'Books') {
      fileType = FileType.custom;
      allowedExtensions = ['pdf', 'doc', 'docx', 'epub'];
      maxBytes = maxBookBytes;
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: fileType,
      allowedExtensions: allowedExtensions,
    );

    if (result == null) return false;

    final file = File(result.files.single.path!);
    final fileName = result.files.single.name;
    final fileSize = file.lengthSync();

    if (fileSize > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).round();
      throw UploadValidationException(
          '"$fileName" is too large (max ${maxMb}MB).');
    }
    if (fileSize == 0) {
      throw const UploadValidationException('That file appears to be empty.');
    }

    try {
      final fileRef =
          FirebaseStorage.instance.ref().child(storagePath).child(fileName);

      debugPrint('Attempting to upload to: $storagePath/$fileName');

      final uploadTask = fileRef.putFile(file);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection(collectionPath).add({
        'fileName': fileName,
        'fileUrl': downloadUrl,
        'downloadUrl': downloadUrl,
        'fileType': storagePath,
        'uploadDate': FieldValue.serverTimestamp(),
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSize': fileSize,
      });

      debugPrint('File uploaded successfully to $storagePath');
      debugPrint('Saved to Firestore collection: $collectionPath');
      return true;
    } on FirebaseException catch (e) {
      debugPrint('Upload error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  static Future<File> saveFilePermanently(PlatformFile file) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final newFile = File('${appStorage.path}/${file.name}');
    return File(file.path!).copy(newFile.path);
  }

  static void openFile(PlatformFile file) {
    OpenFile.open(file.path!);
  }
}
