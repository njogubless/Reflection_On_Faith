import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/books/data/models/book_model.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:flutter/foundation.dart';

// Provider for books from Firestore
final booksProvider = StreamProvider<List<BookModel>>((ref) {
  return FirebaseFirestore.instance
      .collection(
          FirebaseConstants.testimonyCollection) // or your book collection
      .snapshots()
      .map((snapshot) {
    final books = <BookModel>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        // Validate required fields
        if (data['fileName'] == null && data['title'] == null) {
          debugPrint('Skipping document ${doc.id}: No fileName or title');
          continue;
        }

        // Create book model with fallback values
        final book = BookModel(
          id: doc.id,
          title: _getStringValue(data, 'title') ??
              _getStringValue(data, 'fileName') ??
              'Unknown Title',
          author: _getStringValue(data, 'author') ??
              _getStringValue(data, 'authorName') ??
              'Unknown Author',
          fileName: _getStringValue(data, 'fileName') ??
              '${_getStringValue(data, 'title') ?? 'book'}.pdf',
          fileUrl: _getStringValue(data, 'fileUrl') ??
              _getStringValue(data, 'downloadUrl') ??
              '',
          downloadUrl: _getStringValue(data, 'downloadUrl') ??
              _getStringValue(data, 'fileUrl') ??
              '',
          storagePath: _getStringValue(data, 'storagePath') ??
              _getStringValue(data, 'filePath') ??
              '',
          coverUrl: _getStringValue(data, 'coverUrl') ??
              _getStringValue(data, 'thumbnailUrl') ??
              '',
          fileSize: _getIntValue(data, 'fileSize') ?? 0,
          uploadDate: data['uploadDate'] as Timestamp? ??
              data['uploadedAt'] as Timestamp? ??
              Timestamp.now(),
          description: _getStringValue(data, 'description') ?? '',
          category: _getStringValue(data, 'category') ?? 'General',
        );

        // Validate that book has either fileUrl or downloadUrl
        if (book.fileUrl.isEmpty && book.downloadUrl.isEmpty) {
          debugPrint('Skipping book ${book.title}: No download URL available');
          continue;
        }

        books.add(book);
      } catch (e) {
        debugPrint('Error parsing book document ${doc.id}: $e');
        // Continue processing other documents
        continue;
      }
    }

    debugPrint('Total books loaded: ${books.length}');
    return books;
  });
});

// Helper functions to safely extract data
String? _getStringValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;
  if (value is String) return value.isNotEmpty ? value : null;
  return value.toString().isNotEmpty ? value.toString() : null;
}

int? _getIntValue(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

// Provider for downloaded books (stored locally)
final downloadedBooksProvider = StateProvider<Set<String>>((ref) => {});

// Provider for currently reading book
final currentlyReadingProvider = StateProvider<String?>((ref) => null);

// Provider for reading progress
final readingProgressProvider = StateProvider<Map<String, double>>((ref) => {});

// Provider to check if a book is downloaded
final isBookDownloadedProvider = Provider.family<bool, String>((ref, bookId) {
  final downloadedBooks = ref.watch(downloadedBooksProvider);
  return downloadedBooks.contains(bookId);
});

// Provider for filtered books
final filteredBooksProvider =
    Provider.family<List<BookModel>, String?>((ref, query) {
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.when(
    data: (books) {
      if (query == null || query.isEmpty) return books;

      final lowercaseQuery = query.toLowerCase();
      return books.where((book) {
        return book.title.toLowerCase().contains(lowercaseQuery) ||
            book.author.toLowerCase().contains(lowercaseQuery) ||
            book.category.toLowerCase().contains(lowercaseQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for books by category
final booksByCategoryProvider =
    Provider.family<List<BookModel>, String>((ref, category) {
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.when(
    data: (books) {
      if (category.isEmpty || category == 'All') return books;
      return books
          .where(
              (book) => book.category.toLowerCase() == category.toLowerCase())
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for recent books
final recentBooksProvider = Provider<List<BookModel>>((ref) {
  final booksAsync = ref.watch(booksProvider);

  return booksAsync.when(
    data: (books) {
      final sortedBooks = [...books];
      sortedBooks.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
      return sortedBooks.take(10).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
