import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:devotion/core/constants/firebase_constants.dart';

class SplitFileManagementScreen extends StatelessWidget {
  final String audioCollectionPath;
  final String bookCollectionPath;

  const SplitFileManagementScreen({
    super.key,
    this.audioCollectionPath = FirebaseConstants.sermonCollection,
    this.bookCollectionPath = FirebaseConstants.testimonyCollection,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Management'),
      ),
      body: Column(
        children: [
          // Audio Files Section
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.blue.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.audiotrack, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Audio Files',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildFileSection(
                    collectionPath: audioCollectionPath,
                    fileType: 'audio',
                    emptyMessage: 'No audio files uploaded yet',
                  ),
                ),
              ],
            ),
          ),
          // Horizontal divider
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          // Book Files Section
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border(
                      bottom: BorderSide(color: Colors.green.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.book, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Book Files',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildFileSection(
                    collectionPath: bookCollectionPath,
                    fileType: 'book',
                    emptyMessage: 'No book files uploaded yet',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSection({
    required String collectionPath,
    required String fileType,
    required String emptyMessage,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collectionPath).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 8),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final files = snapshot.data?.docs ?? [];

        if (files.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  fileType == 'audio'
                      ? Icons.audiotrack_outlined
                      : Icons.book_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // File count indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: fileType == 'audio'
                    ? Colors.blue.shade50
                    : Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: fileType == 'audio'
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                  ),
                ),
              ),
              child: Text(
                '${files.length} ${files.length == 1 ? 'file' : 'files'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: fileType == 'audio'
                      ? Colors.blue.shade600
                      : Colors.green.shade600,
                ),
              ),
            ),
            // Scrollable file list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: files.length,
                physics: const AlwaysScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final file = files[index];
                  final data = file.data() as Map<String, dynamic>;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: _getFileIcon(fileType),
                      title: Text(
                        data['fileName'] ?? 'Unnamed File',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Uploaded: ${_formatDate(data['uploadDate'] ?? data['uploadedAt'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Text(
                              _formatFileSize(data['fileSize'] ?? 0),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade400,
                          size: 22,
                        ),
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          file.id,
                          data['fileUrl'] ?? data['downloadUrl'],
                          collectionPath,
                          data['fileName'] ?? 'this file',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _getFileIcon(String fileType) {
    IconData iconData;
    Color color;

    switch (fileType.toLowerCase()) {
      case 'audio':
        iconData = Icons.audiotrack;
        color = Colors.blue;
        break;
      case 'book':
        iconData = Icons.menu_book;
        color = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown date';
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String docId,
    String? fileUrl,
    String collectionPath,
    String fileName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (fileUrl != null) {
                _deleteFile(context, docId, fileUrl, collectionPath);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFile(
    BuildContext context,
    String docId,
    String fileUrl,
    String collectionPath,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();

      await FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(docId)
          .delete();

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('File deleted successfully')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting file: $e')),
      );
    }
  }
}
