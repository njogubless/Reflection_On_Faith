import 'package:devotion/features/Profile/Data/Model/user_profile.dart';
import 'package:devotion/features/Profile/Data/repository/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';


final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.getUserProfile();
});


final selectedGenresProvider = StateProvider<List<String>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.favoriteGenres ?? [];
});

final bioTextProvider = StateProvider<String>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  return profile?.bio ?? '';
});


final isProfileLoadingProvider = StateProvider<bool>((ref) => false);

final availableGenresProvider = Provider<List<String>>((ref) {
  return [
    'Gospel', 'Worship', 'Contemporary Christian', 'Christian Rock', 
    'Choral', 'Hymns', 'Christian Hip Hop', 'Christian Pop'
  ];
});