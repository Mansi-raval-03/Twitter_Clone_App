import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: widget.profileImage.isNotEmpty
                    ? NetworkImage(widget.profileImage)
                    : const NetworkImage(
                        'https://www.shutterstock.com/shutterstock/photos/1792956484/display_1500/stock-photo-portrait-of-caucasian-female-in-active-wear-sitting-in-lotus-pose-feeling-zen-and-recreation-during-1792956484.jpg',
                      ),
                child: widget.profileImage.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: widget.controller,
                      maxLines: null,
                      minLines: 3,
                      decoration: InputDecoration(
                        hintText: "What's happening?",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 18, height: 1.35),
                    ),
                    if (_imageFile != null) ...[
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: removeImage,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: pickImage,
                icon: const Icon(Icons.image_outlined),
                color: Colors.lightBlueAccent,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.gif_box_outlined),
                color: Colors.lightBlueAccent,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.poll_outlined),
                color: Colors.lightBlueAccent,
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.lightBlueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: widget.onTweet,
                child: const Text(
                  'Post',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
