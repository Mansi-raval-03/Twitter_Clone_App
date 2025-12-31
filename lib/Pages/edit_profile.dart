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
  bool _isLoading = false;
  String? _initialProfileImageUrl;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _nameController = TextEditingController(text: widget.name ?? '');
    _locationController = TextEditingController(text: widget.location ?? '');
    _websiteController = TextEditingController(text: widget.website ?? '');

    // If caller didn't provide profile fields (empty strings), load from Firestore
    if ((widget.username.trim().isEmpty && widget.bio.trim().isEmpty && widget.profileImageUrl.trim().isEmpty) ||
        widget.profileImageUrl.trim().isEmpty) {
      _loadProfile();
    } else {
      _initialProfileImageUrl = widget.profileImageUrl;
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        _usernameController.text = (data['username'] ?? _usernameController.text).toString();
        _bioController.text = (data['bio'] ?? _bioController.text).toString();
        _nameController.text = (data['name'] ?? _nameController.text).toString();
        _locationController.text = (data['location'] ?? _locationController.text).toString();
        _websiteController.text = (data['website'] ?? _websiteController.text).toString();
        _initialProfileImageUrl = (data['profileImage'] ?? data['profilePicture'] ?? '').toString();
      }
    } catch (_) {
      // ignore load errors; keep defaults
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ProfileController? _profileCtrl;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  XFile? _pickedImage;
  bool _isUploadingCover = false;
  String? _uploadedProfilePath;
  String? _uploadedCoverPath;

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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: Theme.of(context).appBarTheme.elevation ?? 1,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                      Positioned(
                        bottom: 0,
                        left: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black87,
                          child: IconButton(
                            icon: _isUploadingCover ? const SizedBox(width:20,height:20, child:CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : const Icon(Icons.photo_size_select_large, color: Colors.white),
                            onPressed: _isUploadingCover ? null : () async {
                              await _pickAndUploadCover();
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
      if (!mounted) return;
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
        _profileCtrl ??= Get.find<ProfileController>();
        await _profileCtrl!.loadCurrentUser();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      if (!mounted) return;
      Navigator.pop(context, updates);
    } catch (e) {
      if (!mounted) return;
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
    final source = (_initialProfileImageUrl != null && _initialProfileImageUrl!.trim().isNotEmpty)
        ? _initialProfileImageUrl!
        : widget.profileImageUrl;
    final raw = source.trim();
    if (raw.isEmpty) {
      return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
    }

    if (raw.startsWith('http')) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(raw));
    }

    // treat as storage path or gs:// link -> resolve safely
    return FutureBuilder<String?>(
      future: _resolveStorageOrUrl(raw),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const CircleAvatar(radius: 50);
        if (snap.hasError) return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
        final url = snap.data;
        if (url == null || url.isEmpty) return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
        return CircleAvatar(radius: 50, backgroundImage: NetworkImage(url));
      },
    );
  }

  Future<String?> _resolveStorageOrUrl(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http')) return trimmed;
    if (trimmed.startsWith('gs://')) {
      // convert gs:// to a storage reference if possible
      try {
        // FirebaseStorage can accept gs:// style via refFromURL
        final ref = FirebaseStorage.instance.refFromURL(trimmed);
        return await ref.getDownloadURL();
      } catch (_) {
        return null;
      }
    }

    try {
      final ref = FirebaseStorage.instance.ref(trimmed);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
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
      // Save download URL (safer) instead of storage path to avoid ref lookup errors
      final downloadUrl = await ref.getDownloadURL();
      _uploadedProfilePath = downloadUrl;
      // reflect uploaded url locally so avatar resolves immediately
      _initialProfileImageUrl = _uploadedProfilePath;

      // Immediately persist the profileImage download URL so other screens see it
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'profileImage': _uploadedProfilePath, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      try {
        await _profileCtrl?.loadCurrentUser();
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

  Future<void> _pickAndUploadCover() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    } 

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
 
    setState(() { _isUploadingCover = true; });

    try {
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('users/$uid/cover_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(file);
      await uploadTask.whenComplete(() {});
      final downloadUrl = await ref.getDownloadURL();
      _uploadedCoverPath = downloadUrl;

      // Persist the coverImage download URL
      await FirebaseFirestore.instance.collection('users').doc(uid).set({'coverImage': _uploadedCoverPath, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      try {
        await _profileCtrl?.loadCurrentUser();
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cover image uploaded')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cover upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }
}
