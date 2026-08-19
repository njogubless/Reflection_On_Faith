import 'package:devotion/services/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchProvider);
    final searchNotifier = ref.read(searchProvider.notifier);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: searchState.isSearching
          ? TextField(
              autofocus: true,
              style: TextStyle(color: onPrimary, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search articles, audio, books...',
                hintStyle: TextStyle(color: onPrimary.withValues(alpha: 0.7), fontSize: 16),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: onPrimary.withValues(alpha: 0.7)),
                  onPressed: () => searchNotifier.stopSearch(),
                ),
              ),
              onChanged: (query) => searchNotifier.performSearch(query),
            )
          // Previously this fell back to `screens[selectedIndex].runtimeType
          // .toString()` for every tab except the first — i.e. it showed the
          // literal Dart class name ("AudioScreen", "ArticlePage", ...) as
          // the on-screen title instead of the human-readable one the
          // caller already computed and passed in.
          : Text(title),
      actions: [
        IconButton(
          icon: Icon(
            searchState.isSearching ? Icons.search_off : Icons.search,
          ),
          onPressed: () {
            if (searchState.isSearching) {
              searchNotifier.stopSearch();
            } else {
              searchNotifier.startSearch();
            }
          },
        ),
      ],
    );
  }
}
