import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/core/constants/firebase_constants.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:devotion/features/audio/presentation/providers/audio_recorder_provider.dart';
import 'package:devotion/features/audio/presentation/screens/audio_recoding_state.dart';
import 'package:devotion/features/audio/presentation/widgets/wave_form_painter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecordAudioPage extends ConsumerStatefulWidget {
  const RecordAudioPage({super.key});

  @override
  ConsumerState<RecordAudioPage> createState() => _RecordAudioPageState();
}

class _RecordAudioPageState extends ConsumerState<RecordAudioPage> {
  final _titleController = TextEditingController();
  final _scriptureController = TextEditingController();
  final _ministerController = TextEditingController();
  bool _isSubmitting = false;
  bool _didShowLimitNotice = false;

  @override
  void dispose() {
    _titleController.dispose();
    _scriptureController.dispose();
    _ministerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _submitRecording() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final recordingState = ref.read(audioRecorderProvider);

    if (recordingState.recordedFilePath == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No recording available')),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _scriptureController.text.trim().isEmpty ||
        _ministerController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    // Belt-and-suspenders: the recorder already auto-stops at the cap, and
    // firestore.rules reject any Devotion write over it too — this just
    // avoids even attempting the upload if it somehow got here anyway.
    if (recordingState.recordingDuration > AudioRecordingState.maxDuration) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Recording exceeds the 25-minute sermon limit.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a recording')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio')
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');

      final audioFile = File(recordingState.recordedFilePath!);
      final uploadTask = await storageRef.putFile(audioFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final devotionDoc = AudioFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        url: downloadUrl,
        coverUrl: '',
        duration: recordingState.recordingDuration,
        setUrl: '',
        uploaderId: user.uid,
        uploadDate: DateTime.now(),
        scripture: _scriptureController.text.trim(),
        minister: _ministerController.text.trim(),
        approvalStatus: 'pending',
      );

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.devotionCollection)
          .doc(devotionDoc.id)
          .set(devotionDoc.toJson());

      navigator.pop(); // dismiss the progress dialog

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Recording submitted for review'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop(); // leave the recording page
    } catch (e) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Could not upload the recording. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(audioRecorderProvider);
    final theme = Theme.of(context);

    if (recordingState.didHitDurationLimit && !_didShowLimitNotice) {
      _didShowLimitNotice = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Recording automatically stopped at the 25-minute sermon limit.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }

    Widget buildControlButton({
      required VoidCallback onPressed,
      required IconData icon,
      required Color color,
    }) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          elevation: 0,
          child: Icon(icon, size: 32),
        ),
      );
    }

    Widget buildInputField({
      required TextEditingController controller,
      required String label,
      required IconData icon,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: theme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor),
            ),
            filled: true,
            fillColor: theme.cardColor,
          ),
        ),
      );
    }

    Widget buildRecordingSection() {
      final warning = recordingState.isNearDurationLimit;
      final timerColor = warning ? Colors.deepOrange : theme.primaryColor;
      final progress = recordingState.recordingDuration.inMilliseconds /
          AudioRecordingState.maxDuration.inMilliseconds;

      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_formatDuration(recordingState.recordingDuration)} / ${_formatDuration(AudioRecordingState.maxDuration)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: timerColor,
              ),
            ),
            if (warning && recordingState.isRecording) ...[
              const SizedBox(height: 4),
              const Text(
                'Approaching the 25-minute sermon limit',
                style: TextStyle(color: Colors.deepOrange, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(timerColor),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomPaint(
                painter: WaveformPainter(
                  waveformData: recordingState.waveformData,
                ),
                size: const Size(double.infinity, 100),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!recordingState.isRecording)
                  buildControlButton(
                    onPressed: () => ref
                        .read(audioRecorderProvider.notifier)
                        .startRecording(),
                    icon: Icons.mic,
                    color: Colors.red,
                  )
                else ...[
                  buildControlButton(
                    onPressed: recordingState.isPaused
                        ? () => ref
                            .read(audioRecorderProvider.notifier)
                            .resumeRecording()
                        : () => ref
                            .read(audioRecorderProvider.notifier)
                            .pauseRecording(),
                    icon: recordingState.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 24),
                  buildControlButton(
                    onPressed: () =>
                        ref.read(audioRecorderProvider.notifier).stopRecording(),
                    icon: Icons.stop,
                    color: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withValues(alpha: 0.05),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Record Sermon'),
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    buildInputField(
                      controller: _titleController,
                      label: 'Sermon Title',
                      icon: Icons.title,
                    ),
                    buildInputField(
                      controller: _scriptureController,
                      label: 'Scripture Reference',
                      icon: Icons.book,
                    ),
                    buildInputField(
                      controller: _ministerController,
                      label: 'Minister Name',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 24),
                    buildRecordingSection(),
                    if (recordingState.recordedFilePath != null) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.upload),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit for Review',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
