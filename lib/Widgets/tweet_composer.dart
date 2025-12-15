import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class TweetComposerWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onTweet;
  final String username;
  final String handle;
  final String profileImage;

  const TweetComposerWidget({
    super.key,
    required this.controller,
    required this.onTweet,
    required this.username,
    required this.handle,
    required this.profileImage,
  });

  @override
  State<TweetComposerWidget> createState() => TweetComposerWidgetState();
}

class TweetComposerWidgetState extends State<TweetComposerWidget> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  /// Public getter to access the selected image
  File? get imageFile => _imageFile;

  /// Pick image from gallery
  Future<void> pickImage() async {
    final pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// Remove selected image
  void removeImage() {
    setState(() {
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        DateFormat('hh:mm a • dd MMM yy').format(DateTime.now());

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar, username, handle, timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.profileImage.isNotEmpty
                    ? NetworkImage(widget.profileImage)
                    : NetworkImage('https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg'),
                child:
                    widget.profileImage.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.handle,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeString,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content input field
          TextField(
            controller: widget.controller,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: "What's happening?",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Image preview
          if (_imageFile != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFile!),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: removeImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          // Image picker button
          Row(
            children: [
              IconButton(
                onPressed: pickImage,
                icon: const Icon(Icons.image_outlined),
              ),
              const Text('Add Image'),
            ],
          ),
          const SizedBox(height: 16),
          // Tweet button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (widget.controller.text.trim().isEmpty && _imageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tweet cannot be empty')),
                  );
                  return;
                }
                widget.onTweet();
              },
              child: const Text('Tweet'),
            ),
          ),
        ],
      ),
    );
  }
}
