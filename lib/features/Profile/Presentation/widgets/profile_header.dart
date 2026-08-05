import 'package:devotion/features/Profile/Data/Model/user_profile.dart';
import 'package:devotion/features/Profile/Data/repository/profile_repository.dart';
import 'package:devotion/features/Profile/Domain/Providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends ConsumerWidget {
  final UserProfile profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  Future<void> _uploadProfilePicture(
      BuildContext context, WidgetRef ref) async {
    final isLoading = ref.read(isProfileLoadingProvider);
    if (isLoading) return;

    ref.read(isProfileLoadingProvider.notifier).state = true;

    try {
      final picker = ImagePicker();
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) {
        ref.read(isProfileLoadingProvider.notifier).state = false;
        return;
      }

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (pickedFile != null) {
        final repository = ref.read(profileRepositoryProvider);
        await repository.uploadProfilePicture(pickedFile);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      ref.read(isProfileLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(isProfileLoadingProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _uploadProfilePicture(context, ref),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : ClipOval(
                          child: profile.avatarUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: profile.avatarUrl!,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.person,
                                          size: 60, color: theme.colorScheme.onSurfaceVariant),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Icon(Icons.person,
                                  size: 60, color: theme.colorScheme.onSurfaceVariant),
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          if (profile.favoriteGenres.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: profile.favoriteGenres
                  .map((genre) => Chip(label: Text(genre)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
