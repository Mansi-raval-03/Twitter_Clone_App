import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twitter_clone_app/Pages/messages_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_detail_screen.dart';
import 'package:twitter_clone_app/tweet/tweet_model.dart';

class TweetCardWidget extends StatefulWidget {
  final TweetModel tweet;

  const TweetCardWidget({super.key, required this.tweet});

  @override
  State<TweetCardWidget> createState() => _TweetCardWidgetState();
}

class _TweetCardWidgetState extends State<TweetCardWidget> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.tweet.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('hh:mm a • dd MMM yy').format(widget.tweet.createdAt);

    final words = widget.tweet.content.split(' ');
    final List<InlineSpan> textSpans = words.map((word) {
      if (word.startsWith('#')) {
        return TextSpan(
          text: '$word ',
          style: const TextStyle(color: Colors.blue),
        );
      } else {
        return TextSpan(text: '$word ');
      }
    }).toList();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TweetDetailScreen(tweet: widget.tweet)),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: widget.tweet.profileImage.isNotEmpty
                        ? NetworkImage(widget.tweet.profileImage)
                        : null,
                    radius: 20,
                    child: widget.tweet.profileImage.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tweet.username,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.tweet.handle,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeString,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tweet content
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 15),
                  children: textSpans,
                ),
              ),
              if (widget.tweet.imageUrl.isNotEmpty)
                Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(widget.tweet.imageUrl),
    ),
  ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MessagesScreen()),
                      );
                    },
                    icon: const Icon(Icons.comment_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Repost tapped');
                    },
                    icon: const Icon(Icons.repeat),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        isLiked = !isLiked;
                        if (isLiked) {
                          widget.tweet.like();
                        } else {
                          widget.tweet.unlike();
                        }
                      });
                    },
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      debugPrint('Share tapped');
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
