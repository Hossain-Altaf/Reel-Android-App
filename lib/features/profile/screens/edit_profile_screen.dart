import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  File? _newAvatar;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _usernameController = TextEditingController(text: user?.username ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _newAvatar = File(picked.path));
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarFile: _newAvatar,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _newAvatar != null
                    ? FileImage(_newAvatar!)
                    : (user?.avatarUrl.isNotEmpty ?? false)
                    ? NetworkImage(user!.avatarUrl) as ImageProvider
                    : null,
                child: (_newAvatar == null && (user?.avatarUrl.isEmpty ?? true))
                    ? const Icon(Icons.camera_alt, size: 32)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tap to change photo', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
              maxLength: 150,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}