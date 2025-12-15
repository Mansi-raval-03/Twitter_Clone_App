class UserProfile {
  final String name;
  final String username;
  final String bio;
  final String location;
  final String email;
  final String profileImage;
  final String coverImage;
  final int posts;
  final int followers;
  final int following;
  final int likes;

  const UserProfile({
    required this.name,
    required this.username,
    required this.bio,
    required this.location,
    required this.email,
    required this.profileImage,
    required this.coverImage,
    required this.posts,
    required this.followers,
    required this.following,
    required this.likes,
  });
}
