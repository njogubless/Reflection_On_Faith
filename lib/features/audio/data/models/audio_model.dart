import 'package:cloud_firestore/cloud_firestore.dart';

/// Unified audio file model that handles both Firestore schemas:
///
/// Schema A — `Devotion` collection (recorded in-app):
///   coverUrl, duration, id, minister, scripture, setUrl,
///   title, uploadDate, uploaderId, url, approvalStatus
///
/// Schema B — `Sermons` collection (uploaded externally):
///   downloadUrl, fileName, fileSize, fileType, uploadedAt
///
/// Both are normalised into this single model. Fields that don't exist in a
/// given schema fall back to sensible defaults so the UI never crashes.
class AudioFile {
  final String id;
  final String title;
  final String url;        // populated from `url` (A) or `downloadUrl` (B)
  final String coverUrl;
  final Duration duration; // stored as int seconds in Firestore
  final String setUrl;
  final String uploaderId;
  final DateTime uploadDate;
  final String scripture;
  final String minister;
  final String approvalStatus;
  final DateTime? approvedDate;

  // Schema B — extra fields, null when coming from Devotion collection.
  final String? fileName;
  final int? fileSize;
  final String? fileType;

  const AudioFile({
    required this.id,
    required this.title,
    required this.url,
    required this.coverUrl,
    required this.duration,
    required this.setUrl,
    required this.uploaderId,
    required this.uploadDate,
    required this.scripture,
    this.minister = '',
    this.approvalStatus = 'pending',
    this.approvedDate,
    this.fileName,
    this.fileSize,
    this.fileType,
  });

  // ---------------------------------------------------------------------------
  // fromJson — handles both schemas transparently
  // ---------------------------------------------------------------------------
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    // --- URL: Schema A uses `url`, Schema B uses `downloadUrl` ---
    final url = (json['url'] as String? ?? json['downloadUrl'] as String? ?? '');

    // --- ID: Schema A stores `id` as a field, Schema B uses the doc ID
    //         which is passed in separately. Fall back to empty string so
    //         the caller can override with the document ID if needed. ---
    final id = (json['id'] as String? ?? '');

    // --- Title: Schema A uses `title`, Schema B derives it from `fileName` ---
    final rawFileName = json['fileName'] as String? ?? '';
    final title = (json['title'] as String?)?.isNotEmpty == true
        ? json['title'] as String
        : _titleFromFileName(rawFileName);

    // --- Duration: Schema A stores seconds as int, Schema B has no duration ---
    final durationSeconds = json['duration'];
    final duration = durationSeconds != null
        ? Duration(seconds: (durationSeconds as num).toInt())
        : Duration.zero;

    // --- Upload date: Schema A uses ISO string, Schema B uses Timestamp ---
    DateTime uploadDate = DateTime.now();
    final rawDate = json['uploadDate'] ?? json['uploadedAt'];
    if (rawDate is Timestamp) {
      uploadDate = rawDate.toDate();
    } else if (rawDate is String) {
      uploadDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    }

    // --- approvedDate ---
    DateTime? approvedDate;
    final rawApprovedDate = json['approvedDate'];
    if (rawApprovedDate is String) {
      approvedDate = DateTime.tryParse(rawApprovedDate);
    } else if (rawApprovedDate is Timestamp) {
      approvedDate = rawApprovedDate.toDate();
    }

    return AudioFile(
      id: id,
      title: title,
      url: url,
      coverUrl: json['coverUrl'] as String? ?? '',
      duration: duration,
      setUrl: json['setUrl'] as String? ?? '',
      uploaderId: json['uploaderId'] as String? ?? '',
      uploadDate: uploadDate,
      scripture: json['scripture'] as String? ?? '',
      minister: json['minister'] as String? ?? '',
      approvalStatus: json['approvalStatus'] as String? ?? 'pending',
      approvedDate: approvedDate,
      fileName: rawFileName.isNotEmpty ? rawFileName : null,
      fileSize: json['fileSize'] as int?,
      fileType: json['fileType'] as String?,
    );
  }

  // ---------------------------------------------------------------------------
  // fromSnapshot — convenience factory that fills in the document ID
  // automatically, fixing the case where Schema B has no `id` field.
  // ---------------------------------------------------------------------------
  factory AudioFile.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final file = AudioFile.fromJson(data);
    // If the stored id is empty, use the Firestore document ID.
    if (file.id.isEmpty) {
      return AudioFile(
        id: doc.id,
        title: file.title,
        url: file.url,
        coverUrl: file.coverUrl,
        duration: file.duration,
        setUrl: file.setUrl,
        uploaderId: file.uploaderId,
        uploadDate: file.uploadDate,
        scripture: file.scripture,
        minister: file.minister,
        approvalStatus: file.approvalStatus,
        approvedDate: file.approvedDate,
        fileName: file.fileName,
        fileSize: file.fileSize,
        fileType: file.fileType,
      );
    }
    return file;
  }

  // ---------------------------------------------------------------------------
  // toJson — writes Schema A format (used when recording in-app)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'coverUrl': coverUrl,
        'duration': duration.inSeconds,
        'setUrl': setUrl,
        'uploaderId': uploaderId,
        'uploadDate': uploadDate.toIso8601String(),
        'scripture': scripture,
        'minister': minister,
        'approvalStatus': approvalStatus,
        if (approvedDate != null)
          'approvedDate': approvedDate!.toIso8601String(),
      };

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Derives a human-readable title from a file name like
  /// "Prayer-and-fasting-4-Arise-and-shine.mp3" → "Prayer and fasting 4 Arise and shine"
  static String _titleFromFileName(String fileName) {
    if (fileName.isEmpty) return 'Untitled';
    final withoutExtension =
        fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
    return withoutExtension.replaceAll(RegExp(r'[-_]'), ' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AudioFile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}