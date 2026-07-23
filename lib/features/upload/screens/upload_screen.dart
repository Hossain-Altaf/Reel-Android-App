import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import '../../../providers/feed_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _videoFile;
  final _captionController = TextEditingController();
  bool _uploading = false;
  String? _error;

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 90),
    );
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_videoFile == null) {
      setState(() => _error = 'Pick a video first');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });

    try {
      final compressed = await VideoCompress.compressVideo(
        _videoFile!.path,
        quality: VideoQuality.MediumQuality,
        includeAudio: true,
      );
      final fileToUpload = compressed?.file ?? _videoFile!;

      // Grab a frame from the video to use as the grid thumbnail.
      File? thumbnailFile;
      try {
        final thumb = await VideoCompress.getFileThumbnail(
          fileToUpload.path,
          quality: 50,
          position: -1, // -1 = grab a frame from partway through, not just frame 0
        );
        thumbnailFile = thumb;
      } catch (_) {
        // If thumbnail generation fails for any reason, just upload without one —
        // not worth blocking the whole upload over a missing thumbnail.
      }

      await ref.read(reelServiceProvider).uploadReel(
        videoFile: fileToUpload,
        caption: _captionController.text.trim(),
        thumbnailFile: thumbnailFile,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Reel')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploading ? null : _pickVideo,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _videoFile == null
                    ? const Center(
                    child: Icon(Icons.video_call, size: 48, color: Colors.white54))
                    : const Center(
                    child: Icon(Icons.check_circle, size: 48, color: Colors.greenAccent)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Caption'),
              maxLength: 150,
            ),
            const SizedBox(height: 12),
            if (_uploading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              onPressed: _uploading ? null : _submit,
              child: Text(_uploading ? 'Uploading...' : 'Post Reel'),
            ),
          ],
        ),
      ),
    );
  }
}