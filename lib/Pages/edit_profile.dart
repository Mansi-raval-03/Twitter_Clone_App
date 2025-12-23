import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:twitter_clone_app/controller/profile_controller.dart';

class EditProfilePage extends StatefulWidget {
  final String username;
  final String bio;
  final String profileImageUrl;

  // New optional fields to prefill
  final String? name;
  final String? location;
  final String? website;

  const EditProfilePage({
    super.key,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    this.name,
    this.location,
    this.website,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _nameController = TextEditingController(text: widget.name ?? '');
    _locationController = TextEditingController(text: widget.location ?? '');
    _websiteController = TextEditingController(text: widget.website ?? '');
  }

  final ProfileController _profileCtrl = Get.find();
  bool _isSaving = false;
  bool _isUploadingImage = false;
  XFile? _pickedImage;
  String? _uploadedProfilePath;

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: Colors.blue, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.blue[100],
              height: 150,
              child: Center(
                child: Stack(
                  children: [
                    _buildProfileAvatar(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: _isUploadingImage ? const SizedBox(width:20,height:20, child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _isUploadingImage ? null : () async {
                            await _pickAndUploadImage();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTextField('Name', _nameController),
                  _buildTextField('Username', _usernameController),
                  _buildTextField('Bio', _bioController, maxLines: 3),
                  _buildTextField('Location', _locationController),
                  _buildTextField('Website', _websiteController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final updates = <String, dynamic>{
      'username': _usernameController.text.trim(),
      'bio': _bioController.text.trim(),
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'website': _websiteController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(updates, SetOptions(merge: true));

      // Refresh controller so profile screen updates
      try {
        await _profileCtrl.loadCurrentUser();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context, updates);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.all(12),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    // Local picked image preview
    if (_pickedImage != null) {
      return CircleAvatar(radius: 50, backgroundImage: FileImage(File(_pickedImage!.path)));
    }

    final raw = widget.profileImageUrl.trim();
    if (raw.isEmpty) {
      return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
    }

    if (raw.startsWith('http')) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(raw));
    }

    // treat as storage path
    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(raw).getDownloadURL(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const CircleAvatar(radius: 50);
        final url = snap.data;
        if (url == null || url.isEmpty) return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
        return CircleAvatar(radius: 50, backgroundImage: NetworkImage(url));
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() {
      _pickedImage = picked;
      _isUploadingImage = true;
    });

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('users/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() {});
      _uploadedProfilePath = ref.fullPath;

      // Immediately persist the profileImage path so other screens see it
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'profileImage': _uploadedProfilePath, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      try {
        await _profileCtrl.loadCurrentUser();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile image uploaded')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      setState(() {
        _pickedImage = null;
      });
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }
}