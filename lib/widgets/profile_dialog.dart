import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/constants.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: user.image,
                width: Constants.screenWidth * 0.4,
                height: Constants.screenWidth * 0.4,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: Constants.screenWidth * 0.4,
                        height: Constants.screenWidth * 0.4,
                        color: Colors.grey.shade300,
                      ),
                    ),
                errorWidget:
                    (context, url, error) => CircleAvatar(
                      radius: Constants.screenWidth * 0.2,
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.blueGrey,
                        size: Constants.screenWidth * 0.15, // Adjusted size
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user.about,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.blueGrey[600]),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ViewProfileScreen(user: user),
                ),
              );
            },
            icon: const Icon(
              Icons.account_circle_rounded,
              size: 22, // Standard button icon size
              color: Colors.white,
            ),
            label: const Text('View Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
