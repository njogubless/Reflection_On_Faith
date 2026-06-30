import 'package:devotion/features/admin/presentation/screens/Adminquestionscreen.dart';
import 'package:devotion/features/admin/presentation/screens/file_management_screen.dart';
import 'package:devotion/features/admin/presentation/screens/upload_files.dart';
import 'package:devotion/features/articles/presentation/screens/aricle_management_screen.dart';
import 'package:devotion/features/audio/presentation/screens/recording_approval.dart';
import 'package:devotion/features/auth/presentation/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:devotion/core/constants/firebase_constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isUploading = false;

  Future<void> uploadFile(
      String collectionPath, String firebasePath, BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isUploading = true);
    try {
      await UploadFiles.uploadFileToFirebase(collectionPath, firebasePath);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SplitFileManagementScreen(),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: _buildDashboardGrid(),
                    ),
                  ),
                ),
                if (_isUploading) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome, Admin!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            _buildStatsCard('Today\'s Uploads', '12'),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your platform with these tools:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildDashboardTile(
          context,
          title: 'Upload Audio',
          icon: Icons.audiotrack,
          color: Colors.blue,
          onTap: () =>
              uploadFile(FirebaseConstants.sermonCollection, 'audio', context),
        ),
        _buildDashboardTile(
          context,
          title: 'Upload Book',
          icon: Icons.book,
          color: Colors.green,
          onTap: () => uploadFile(
              FirebaseConstants.testimonyCollection, 'Books', context),
        ),
        _buildDashboardTile(
          context,
          title: 'Articles Management',
          icon: Icons.article,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ArticleManagementScreen()),
          ),
        ),
        _buildDashboardTile(
          context,
          title: 'Manage Q/A',
          icon: Icons.question_answer_rounded,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminQuestionScreen()),
          ),
        ),
        _buildDashboardTile(
          context,
          title: 'File Management',
          icon: Icons.file_open_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplitFileManagementScreen(),
            ),
          ),
        ),
        _buildDashboardTile(
          context,
          title: 'Recording Approval',
          icon: Icons.approval_rounded,
          color: Colors.indigoAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecordingApprovalPage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.7),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
