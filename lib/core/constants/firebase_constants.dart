class FirebaseConstants {
  static const usersCollection = 'users';
  static const sermonCollection = 'Sermons';
  static const questionsCollection = 'questions';
  static const feedbackCollection = 'feedback';
  static const articleCollection = 'article';
  static const testimonyCollection = 'testimony';
  static const devotionCollection = 'Devotion';
  static const commentsCollection = 'comments';

  /// Maximum length of an in-app recorded sermon. Enforced client-side in
  /// `AudioRecorderNotifier` (auto-stop) and again server-side in
  /// firestore.rules (`duration <= 1500`) on `Devotion` document creates —
  /// keep both in sync if this ever changes.
  static const maxSermonDurationSeconds = 25 * 60;
}