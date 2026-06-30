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
  final _titleController = TextEditingController();
  final _scriptureController = TextEditingController();
  final _ministerController = TextEditingController();

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
    final recordingState = ref.read(audioRecorderProvider);

    if (recordingState.recordedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No recording available')),
      );
      return;
    }

    if (_titleController.text.isEmpty ||
        _scriptureController.text.isEmpty ||
        _ministerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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
          .collection('audio')
          .doc(devotionDoc.id)
          .set(devotionDoc.toJson());

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(audioRecorderProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final formHeight = screenHeight * 0.4;
    final recordingHeight = screenHeight * 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sermon'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          height: screenHeight -
              kToolbarHeight -
              MediaQuery.of(context).padding.top,
          child: Column(
            children: [
              SizedBox(
                height: formHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Sermon Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _scriptureController,
                        decoration: InputDecoration(
                          labelText: 'Scripture Reference',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _ministerController,
                        decoration: InputDecoration(
                          labelText: 'Minister Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: recordingHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (recordingState.isRecording ||
                        recordingState.recordedFilePath != null)
                      SizedBox(
                        height: 100,
                        child: CustomPaint(
                          painter: WaveformPainter(
                            waveformData: recordingState.waveformData,
                          ),
                          size: Size(MediaQuery.of(context).size.width, 100),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      _formatDuration(recordingState.recordingDuration),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!recordingState.isRecording)
                          FloatingActionButton(
                            onPressed: () => ref
                                .read(audioRecorderProvider.notifier)
                                .startRecording(),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.mic),
                          )
                        else ...[
                          FloatingActionButton(
                            onPressed: recordingState.isPaused
                                ? () => ref
                                    .read(audioRecorderProvider.notifier)
                                    .resumeRecording()
                                : () => ref
                                    .read(audioRecorderProvider.notifier)
                                    .pauseRecording(),
                            backgroundColor: Colors.orange,
                            child: Icon(recordingState.isPaused
                                ? Icons.play_arrow
                                : Icons.pause),
                          ),
                          const SizedBox(width: 20),
                          FloatingActionButton(
                            onPressed: () => ref
                                .read(audioRecorderProvider.notifier)
                                .stopRecording(),
                            backgroundColor: Colors.red,
                            child: const Icon(Icons.stop),
                          ),
                        ],
                      ],
                    ),
                    if (recordingState.recordedFilePath != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _submitRecording,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Submit Recording'),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
