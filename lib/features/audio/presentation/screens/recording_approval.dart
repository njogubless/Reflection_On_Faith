import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecordingApprovalPage extends StatefulWidget {
  const RecordingApprovalPage({super.key});

  @override
  State<RecordingApprovalPage> createState() => _RecordingApprovalPageState();
}

class _RecordingApprovalPageState extends State<RecordingApprovalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'pending';

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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildTabBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildRecordingsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Recording Approval',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
            ),
          ),
          _buildPendingBadge(),
        ],
      ),
    );
  }

  Widget _buildPendingBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Devotion')
          .where('approvalStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data?.docs.length ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: pendingCount > 0 ? Colors.red : Colors.grey,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.pending, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {
            _selectedFilter = ['pending', 'approved', 'rejected'][index];
          });
        },
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).primaryColor,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Approved'),
          Tab(text: 'Rejected'),
        ],
      ),
    );
  }

  Widget _buildRecordingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedFilter == 'pending'
          ? FirebaseFirestore.instance
              .collection('Devotion')
              .where('approvalStatus', isEqualTo: 'pending')
              .snapshots()
          : _selectedFilter == 'approved'
              ? FirebaseFirestore.instance
                  .collection('Devotion')
                  .where('approvalStatus', isEqualTo: 'approved')
                  .snapshots()
              : FirebaseFirestore.instance
                  .collection('Devotion')
                  .where('approvalStatus', isEqualTo: 'rejected')
                  .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildRecordingCard(AudioFile.fromJson(data));
          },
        );
      },
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error loading recordings',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final config = {
      'pending': {
        'message': 'No pending recordings',
        'icon': Icons.pending_actions,
        'color': Colors.orange
      },
      'approved': {
        'message': 'No approved recordings',
        'icon': Icons.check_circle,
        'color': Colors.green
      },
      'rejected': {
        'message': 'No rejected recordings',
        'icon': Icons.cancel,
        'color': Colors.red
      },
    }[_selectedFilter]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(config['icon'] as IconData,
              size: 64,
              color: (config['color'] as Color).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(config['message'] as String,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  )),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(AudioFile audioFile) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.withValues(alpha: 0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(audioFile.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildStatusChip(audioFile.approvalStatus),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time, 'Duration',
                  _formatDuration(audioFile.duration)),
              _buildDetailRow(Icons.calendar_today, 'Uploaded',
                  _formatDate(audioFile.uploadDate)),
              if (audioFile.approvalStatus != 'pending') ...[
                const Divider(height: 24),
                _buildDetailRow(
                  audioFile.approvalStatus == 'approved'
                      ? Icons.check
                      : Icons.close,
                  audioFile.approvalStatus == 'approved'
                      ? 'Approved'
                      : 'Rejected',
                  _formatDate(audioFile.approvedDate ?? DateTime.now()),
                ),
              ],
              const SizedBox(height: 16),
              if (audioFile.approvalStatus == 'pending')
                _buildActionButtons(audioFile.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final config = {
      'approved': {'color': Colors.green, 'icon': Icons.check_circle},
      'rejected': {'color': Colors.red, 'icon': Icons.cancel},
      'pending': {'color': Colors.orange, 'icon': Icons.pending},
    }[status]!;

    final color = config['color'] as Color;
    final icon = config['icon'] as IconData;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(status.toUpperCase(),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey[700])),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String recordingId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(recordingId, true),
            icon: const Icon(Icons.check),
            label: const Text('Approve'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(recordingId, false),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showApprovalDialog(String recordingId, bool isApproval) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isApproval ? 'Approve Recording' : 'Reject Recording'),
        content: Text(
          isApproval
              ? 'Are you sure you want to approve this recording? It will be visible to all users.'
              : 'Are you sure you want to reject this recording? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(recordingId, isApproval);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApproval ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApproval ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _processApproval(String recordingId, bool isApproval) async {
    try {
      await FirebaseFirestore.instance
          .collection('Devotion')
          .doc(recordingId)
          .update({
        'approvalStatus': isApproval ? 'approved' : 'rejected',
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
        'approvedDate': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Recording ${isApproval ? 'approved' : 'rejected'} successfully'),
            backgroundColor: isApproval ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${isApproval ? 'approving' : 'rejecting'} recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
