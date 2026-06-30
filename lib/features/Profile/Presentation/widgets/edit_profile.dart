import 'package:devotion/features/Profile/Data/Model/user_profile.dart';
import 'package:devotion/features/Profile/Data/repository/profile_repository.dart';
import 'package:devotion/features/Profile/Domain/Providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileSheet({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late TextEditingController _bioController;
  late List<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _selectedGenres = List.from(widget.profile.favoriteGenres);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final isLoading = ref.read(isProfileLoadingProvider);
    if (isLoading) return;

    ref.read(isProfileLoadingProvider.notifier).state = true;

    try {
      final repository = ref.read(profileRepositoryProvider);
      await repository.updateProfile(
        bio: _bioController.text.trim(),
        favoriteGenres: _selectedGenres,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isProfileLoadingProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isProfileLoadingProvider);
    final availableGenres = ref.watch(availableGenresProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Bio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Favorite Genres',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableGenres.map((genre) {
                  final isSelected = _selectedGenres.contains(genre);
                  return FilterChip(
                    label: Text(genre),
                    selected: isSelected,
                    selectedColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedGenres.length < 5) {
                            _selectedGenres.add(genre);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('You can select up to 5 genres')),
                            );
                          }
                        } else {
                          _selectedGenres.remove(genre);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                          _saveChanges();
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
