import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

class ProfileAvatar extends StatelessWidget {
  final String? profilePicture;
  final String firstName;
  final String lastName;
  final String username;
  final double radius;
  final Color backgroundColor;

  const ProfileAvatar({
    Key? key,
    this.profilePicture,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.radius = 25,
    this.backgroundColor = Colors.blue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = ImageUtils.getFullImageUrl(profilePicture);
    final String initials = ImageUtils.getInitials(firstName, lastName, username);

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: fullImageUrl != null
          ? NetworkImage(fullImageUrl) as ImageProvider
          : null,
      onBackgroundImageError: fullImageUrl != null
          ? (exception, stackTrace) {
        print('Profile image load error: $exception');
      }
          : null,
      child: fullImageUrl == null
          ? Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      )
          : null,
    );
  }
}
