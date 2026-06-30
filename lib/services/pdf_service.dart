// lib/features/books/data/services/pdf_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PdfService {
  static const String _pdfExtension = '.pdf';

  /// Generates a clean filename for a PDF
  static String generatePdfFileName(String? originalFileName, String title) {
    String fileName = originalFileName?.isNotEmpty == true
        ? originalFileName!
        : title.replaceAll(RegExp(r'[^\w\s-]'), '');

    if (!fileName.toLowerCase().endsWith(_pdfExtension)) {
      fileName = '$fileName$_pdfExtension';
    }

    return fileName;
  }

  /// Checks if a PDF file exists locally
  static Future<File?> getLocalPdfFile(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      return await file.exists() ? file : null;
    } catch (e) {
      debugPrint('Error checking local PDF file: $e');
      return null;
    }
  }

  /// Downloads a PDF from URL and saves it locally
  static Future<File> downloadPdf({
    required String downloadUrl,
    required String fileName,
    bool isTemporary = false,
  }) async {
    final response = await http.get(Uri.parse(downloadUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
    }

    final directory = isTemporary
        ? await getTemporaryDirectory()
        : await getApplicationDocumentsDirectory();

    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  /// Gets the appropriate download URL from available options
  static String getDownloadUrl(String downloadUrl, String fileUrl) {
    if (downloadUrl.isNotEmpty) return downloadUrl;
    if (fileUrl.isNotEmpty) return fileUrl;
    throw Exception('No download URL available');
  }

  /// Creates a temporary file for streaming
  static Future<File> createTempPdfFile(
      String bookId, String downloadUrl) async {
    final tempFileName = 'temp_$bookId.pdf';

    return await downloadPdf(
      downloadUrl: downloadUrl,
      fileName: tempFileName,
      isTemporary: true,
    );
  }
}
