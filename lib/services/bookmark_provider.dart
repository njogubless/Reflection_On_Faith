import 'package:devotion/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookmarkedArticlesProvider =
    NotifierProvider<BookmarkNotifier, List<String>>(BookmarkNotifier.new);

class BookmarkNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs == null) return [];
    return prefs.getStringList('bookmarkedArticles') ?? [];
  }

  Future<void> toggleBookmark(String articleId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs == null) return;
    final newState = List<String>.from(state);
    if (state.contains(articleId)) {
      newState.remove(articleId);
    } else {
      newState.add(articleId);
    }
    state = newState;
    await prefs.setStringList('bookmarkedArticles', newState);
  }

  bool isBookmarked(String articleId) => state.contains(articleId);
}
