import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:devotion/features/audio/data/models/audio_model.dart';
import 'package:devotion/features/audio/presentation/providers/audio_recorder_provider.dart';
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

    if (_titleController.text.isEmpty ||
        _scriptureController.text.isEmpty ||
        _ministerController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio')
          .child('${DateTime.now().millisecondsSinceEpoch}.m4a');

      final audioFile = File(recordingState.recordedFilePath!);
      final uploadTask = await storageRef.putFile(audioFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final devotionDoc = AudioFile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text,
        url: downloadUrl,
        coverUrl: '',
        duration: recordingState.recordingDuration,
        setUrl: '',
        uploaderId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
        uploadDate: DateTime.now(),
        scripture: _scriptureController.text,
      );

      await FirebaseFirestore.instance
          .collection('Devotion')
          .doc(devotionDoc.id)
          .set(devotionDoc.toJson());

      navigator.pop();

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Recording uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop();
    } catch (e) {
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error uploading recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  final _titleController = TextEditingController();
  final _scriptureController = TextEditingController();
  final _ministerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(audioRecorderProvider);

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
          color: Colors.white,
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
            prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      );
    }

    Widget buildRecordingSection() {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
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
              _formatDuration(recordingState.recordingDuration),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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
                    onPressed: () => ref
                        .read(audioRecorderProvider.notifier)
                        .stopRecording(),
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
              Theme.of(context).primaryColor.withValues(alpha: 0.05),
              Colors.white,
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
                        onPressed: _submitRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.upload),
                            SizedBox(width: 8),
                            Text(
                              'Submit Recording',
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
