import 'package:devotion/features/Profile/Data/Model/user_profile.dart';
import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final UserProfile profile;

  const ProfileStats({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${profile.playlistCount}', 'Playlists'),
          _buildStatItem('${profile.followersCount}', 'Followers'),
          _buildStatItem('${profile.followingCount}', 'Following'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
