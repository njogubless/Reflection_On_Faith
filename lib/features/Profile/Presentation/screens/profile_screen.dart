import 'package:devotion/core/common/widgets/state_views.dart';
import 'package:devotion/features/Profile/Data/Model/user_profile.dart';
import 'package:devotion/features/Profile/Domain/providers.dart';
import 'package:devotion/features/Profile/Presentation/widgets/edit_profile.dart';
import 'package:devotion/features/Profile/Presentation/widgets/profile_header.dart';
import 'package:devotion/features/Profile/Presentation/widgets/profile_stats.dart';
import 'package:devotion/features/Profile/Presentation/widgets/profile_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileDialog(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return EditProfileSheet(profile: profile);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              final profile = profileAsyncValue.value;
              if (profile != null) {
                _showEditProfileDialog(context, profile);
              }
            },
          ),
        ],
      ),
      body: profileAsyncValue.when(
        data: (profile) {
          if (profile == null) {
            return const EmptyView(
              icon: Icons.person_outline,
              title: 'Please sign in',
              subtitle: 'Sign in to view your profile.',
            );
          }

          return SafeArea(
            child: Column(
              children: [
                ProfileHeader(profile: profile),
                const ProfileStats(),
                const Expanded(child: ProfileTabs()),
              ],
            ),
          );
        },
        loading: () => const LoadingView(),
        error: (error, stack) => ErrorView(
          message: 'Could not load your profile.\n$error',
          onRetry: () => ref.invalidate(userProfileProvider),
        ),
      ),
    );
  }
}
