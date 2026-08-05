// AudioFile normalises two different Firestore document shapes (Devotion
// self-recordings vs. admin-uploaded Sermons) into one model — these tests
// pin that behaviour down, plus the `minister` field, which used to be
// collected in the recording form and then silently discarded because the
// model had nowhere to put it.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AudioFile.fromJson — Schema A (Devotion, in-app recording)', () {
    test('reads title/url/duration/minister directly', () {
      final file = AudioFile.fromJson({
        'id': 'abc123',
        'title': 'Sunday Service',
        'url': 'https://example.com/a.m4a',
        'coverUrl': '',
        'duration': 1200,
        'setUrl': '',
        'uploaderId': 'uid_1',
        'uploadDate': '2026-08-01T10:00:00.000Z',
        'scripture': 'John 3:16',
        'minister': 'Pastor Jane',
        'approvalStatus': 'approved',
      });

      expect(file.id, 'abc123');
      expect(file.title, 'Sunday Service');
      expect(file.url, 'https://example.com/a.m4a');
      expect(file.duration, const Duration(seconds: 1200));
      expect(file.minister, 'Pastor Jane');
      expect(file.approvalStatus, 'approved');
    });

    test('defaults approvalStatus to pending when absent', () {
      final file = AudioFile.fromJson({
        'title': 'x',
        'uploaderId': 'uid_1',
      });
      expect(file.approvalStatus, 'pending');
    });

    test('defaults minister to empty string when absent (older documents)', () {
      final file = AudioFile.fromJson({'title': 'x'});
      expect(file.minister, '');
    });
  });

  group('AudioFile.fromJson — Schema B (Sermons, admin bulk upload)', () {
    test('derives title from fileName when title is missing', () {
      final file = AudioFile.fromJson({
        'fileName': 'Prayer-and-fasting-4-Arise-and-shine.mp3',
        'downloadUrl': 'https://example.com/b.mp3',
        'uploadedAt': Timestamp.fromMillisecondsSinceEpoch(0),
      });

      expect(file.title, 'Prayer and fasting 4 Arise and shine');
      expect(file.url, 'https://example.com/b.mp3');
    });

    test('has no duration (defaults to zero) since Sermons carries none', () {
      final file = AudioFile.fromJson({
        'fileName': 'sermon.mp3',
        'downloadUrl': 'https://example.com/c.mp3',
      });
      expect(file.duration, Duration.zero);
    });

    test('prefers an explicit non-empty title over the derived one', () {
      final file = AudioFile.fromJson({
        'title': 'Explicit Title',
        'fileName': 'ignored-file-name.mp3',
      });
      expect(file.title, 'Explicit Title');
    });
  });

  group('AudioFile.toJson round-trip', () {
    test('preserves duration and minister through toJson -> fromJson', () {
      final original = AudioFile(
        id: '1',
        title: 'Test',
        url: 'https://example.com/x.m4a',
        coverUrl: '',
        duration: const Duration(minutes: 25),
        setUrl: '',
        uploaderId: 'uid_1',
        uploadDate: DateTime.utc(2026, 1, 1),
        scripture: 'Psalm 23',
        minister: 'Pastor Jane',
        approvalStatus: 'pending',
      );

      final roundTripped = AudioFile.fromJson(original.toJson());

      expect(roundTripped.duration, const Duration(minutes: 25));
      expect(roundTripped.minister, 'Pastor Jane');
      expect(roundTripped.approvalStatus, 'pending');
      expect(roundTripped.scripture, 'Psalm 23');
    });
  });
}
