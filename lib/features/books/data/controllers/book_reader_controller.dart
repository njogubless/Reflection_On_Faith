// lib/features/books/presentation/controllers/book_reader_controller.dart
import 'package:devotion/features/books/data/models/book_model.dart';
import 'package:devotion/features/books/data/models/book_reader_state.dart';
import 'package:devotion/services/pdf_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:devotion/features/books/presentation/providers/book_providers.dart';

class BookReaderController extends StateNotifier<BookReaderState> {
  final BookModel book;
  final Ref ref;

  BookReaderController({
    required this.book,
    required this.ref,
  }) : super(const BookReaderState()) {
    _checkLocalFile();
  }

  String get _fileName =>
      PdfService.generatePdfFileName(book.fileName, book.title);

  Future<void> _checkLocalFile() async {
    state = state.copyWith(
      status: BookReaderStatus.loading,
      errorMessage: '',
    );

    try {
      final localFile = await PdfService.getLocalPdfFile(_fileName);

      if (localFile != null) {
        state = state.copyWith(
          status: BookReaderStatus.loaded,
          pdfFile: localFile,
        );
      } else {
        state = state.copyWith(
          status: BookReaderStatus.fileNotFound,
          errorMessage:
              'Book not downloaded yet. Please download to read offline.',
        );
      }
    } catch (e) {
      debugPrint('Error checking local file: $e');
      state = state.copyWith(
        status: BookReaderStatus.error,
        errorMessage: 'Error checking for local file: ${e.toString()}',
      );
    }
  }

  Future<void> downloadAndOpenFile() async {
    state = state.copyWith(
      status: BookReaderStatus.downloading,
      errorMessage: '',
    );

    try {
      final downloadUrl =
          PdfService.getDownloadUrl(book.downloadUrl, book.fileUrl);
      final file = await PdfService.downloadPdf(
        downloadUrl: downloadUrl,
        fileName: _fileName,
      );

      ref.read(downloadedBooksProvider.notifier).update((s) => {...s, book.id});

      state = state.copyWith(
        status: BookReaderStatus.loaded,
        pdfFile: file,
      );
    } catch (e) {
      debugPrint('Download error: $e');
      state = state.copyWith(
        status: BookReaderStatus.error,
        errorMessage: 'Download failed: ${e.toString()}',
      );
    }
  }

  Future<void> streamFile() async {
    state = state.copyWith(
      status: BookReaderStatus.loading,
      errorMessage: '',
    );

    try {
      final downloadUrl =
          PdfService.getDownloadUrl(book.downloadUrl, book.fileUrl);
      final tempFile = await PdfService.createTempPdfFile(book.id, downloadUrl);

      state = state.copyWith(
        status: BookReaderStatus.loaded,
        pdfFile: tempFile,
      );
    } catch (e) {
      debugPrint('Stream error: $e');
      state = state.copyWith(
        status: BookReaderStatus.error,
        errorMessage: 'Failed to stream PDF: ${e.toString()}',
      );
    }
  }

  void updatePageInfo(int? currentPage, int? totalPages) {
    state = state.copyWith(
      currentPage: currentPage ?? state.currentPage,
      totalPages: totalPages ?? state.totalPages,
    );
  }

  void updateTotalPages(int? totalPages) {
    if (totalPages != null) {
      state = state.copyWith(totalPages: totalPages);
    }
  }

  void handlePdfError(dynamic error) {
    debugPrint('PDF Error: $error');
    state = state.copyWith(
      status: BookReaderStatus.error,
      errorMessage: 'PDF Error: ${error.toString()}',
    );
  }

  void handlePageError(int page, dynamic error) {
    debugPrint('Page $page Error: $error');
  }

  void handleViewCreated(PDFViewController controller) {
    debugPrint('PDF View created successfully');
  }

  void retry() => _checkLocalFile();
}

// Provider for the controller
final bookReaderControllerProvider = StateNotifierProvider.family<
    BookReaderController, BookReaderState, BookModel>(
  (ref, book) => BookReaderController(book: book, ref: ref),
);
