import 'dart:io';
import 'package:devotion/features/admin/presentation/screens/admin_log_in.dart';
import 'package:devotion/features/auth/Repository/auth_repository.dart';
import 'package:devotion/features/auth/controller/auth_controller.dart';
import 'package:devotion/services/bookmark_screen.dart';
import 'package:devotion/services/help_support.dart';
import 'package:devotion/services/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isLoading = false;

  Future<void> launchLink(String link) async {
    try {
      if (!await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $link';
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open link: $error')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

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
        setState(() => _isLoading = false);
        return;
      }

      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 500,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final storageRef = FirebaseStorage.instance.ref(
              'user_avatars/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(imageFile);
          final downloadUrl = await storageRef.getDownloadURL();

          await Future.wait([
            FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'avatarUrl': downloadUrl}),
            user.updatePhotoURL(downloadUrl),
          ]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Profile picture updated successfully')),
            );

            setState(() {});
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareApp() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out this amazing app! https://play.google.com/store/apps/details?id=your.app.id',
        subject: 'Reflection On Faith App',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use the already-loaded UserModel from Riverpod — zero extra Firestore reads.
    final userModel = ref.watch(userProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    final displayName = userModel?.displayName ?? 'Guest User';
    final email = userModel?.userEmail ?? 'Sign in to access all features';
    final isAdmin = userModel?.isAdmin ?? false;
    // Avatar falls back to Firebase Auth photoURL (populated by Google Sign-in).
    final avatarUrl = firebaseUser?.photoURL;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: theme.primaryColor,
              image: const DecorationImage(
                image: AssetImage('assets/images/ROF.webp'),
                fit: BoxFit.cover,
                opacity: 0.7,
              ),
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              email,
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: GestureDetector(
              onTap: firebaseUser != null ? _uploadProfilePicture : null,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 32,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : ClipOval(
                            child: avatarUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) =>
                                        _buildFallbackAvatar(
                                            displayName, theme),
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                  )
                                : _buildFallbackAvatar(displayName, theme),
                          ),
                  ),
                  if (firebaseUser != null)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                if (firebaseUser != null) ...[
                  const ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                  ),
                ],
                if (isAdmin)
                  ListTile(
                    leading: const Icon(Icons.lock),
                    title: const Text('Admin Login'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AdminLoginPage()),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text("Website"),
                  subtitle: const Text("Visit Reflection On Faith"),
                  onTap: () => launchLink("https://andrewcphiri.com/"),
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("Share App"),
                  onTap: _shareApp,
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('Bookmarks'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BookmarksScreen()));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Settings"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SettingsPage()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text("Help & Support"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HelpSupportPage()));
                  },
                ),
                if (firebaseUser != null)
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Sign Out'),
                          content:
                              const Text('Are you sure you want to sign out?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Sign Out'),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        final authRepository = ref.read(authRepositoryProvider);
                        await authRepository.signOutUser();
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Version 1.0.0',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name, ThemeData theme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}
