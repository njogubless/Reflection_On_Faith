import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreMigration {
  static Future<void> updateBooksCollection() async {
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore.collection('books').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        String fileName = data['fileName'] as String? ?? '';
        String title = data['title'] as String? ?? '';

        if (title.isEmpty && fileName.isNotEmpty) {
          title = fileName
              .replaceAll('.pdf', '')
              .replaceAll('(Z-Library)', '')
              .trim();
        }

        Map<String, dynamic> updatedData = {
          ...data,
          'title': title.isNotEmpty ? title : 'Unknown Title',
          'author': data['author'] ?? 'Unknown Author',
          'description': data['description'] ?? 'No description available',
          'coverUrl': data['coverUrl'] ?? _generatePlaceholderCover(title),
          'fileUrl': data['downloadUrl'] ?? data['fileUrl'] ?? '',
          'storagePath': data['storagePath'] ?? 'books/$fileName',
        };

        await doc.reference.update(updatedData);
        // ignore: avoid_print
        print('Updated document: ${doc.id}');
      }

      // ignore: avoid_print
      print('Migration completed successfully!');
    } catch (e) {
      // ignore: avoid_print
      print('Migration failed: $e');
    }
  }

  static String _generatePlaceholderCover(String title) {
    final encodedTitle = Uri.encodeComponent(title.isNotEmpty ? title : 'Book');
    return 'https://ui-avatars.com/api/?name=$encodedTitle&size=300&background=6366f1&color=white&format=png';
  }
}
