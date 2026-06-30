import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileTabs extends StatefulWidget {
  const ProfileTabs({super.key});

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'My Playlists'),
            Tab(text: 'Recently Played'),
            Tab(text: 'Favorites'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPlaylistsTab(),
              _buildRecentlyPlayedTab(),
              _buildFavoritesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildPlaylistItem(
          title: 'My Playlist ${index + 1}',
          description: '${(index + 3) * 2} tracks',
          imageUrl: null,
        );
      },
    );
  }

  Widget _buildRecentlyPlayedTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildTrackItem(
          title: 'Recently Played Track ${index + 1}',
          artist: 'Artist ${index + 1}',
          imageUrl: null,
          playedAt: DateTime.now().subtract(Duration(hours: index)),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildTrackItem(
          title: 'Favorite Track ${index + 1}',
          artist: 'Artist ${index + 1}',
          imageUrl: null,
        );
      },
    );
  }

  Widget _buildPlaylistItem({
    required String title,
    required String description,
    String? imageUrl,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Icon(Icons.music_note),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note),
                  ),
                )
              : const Icon(Icons.music_note, size: 30),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.play_circle_filled),
        onTap: () {},
      ),
    );
  }

  Widget _buildTrackItem({
    required String title,
    required String artist,
    String? imageUrl,
    DateTime? playedAt,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Icon(Icons.music_note),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.music_note),
                  ),
                )
              : const Icon(Icons.music_note),
        ),
        title: Text(title),
        subtitle: Text(artist),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (playedAt != null)
              Text(
                '${playedAt.hour}:${playedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
