import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'chat_screen.dart';

class ViewProfileScreen extends StatelessWidget {
  final ChatUser user;
  const ViewProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: () {
                  // TODO: Implement zoom-in functionality
                },
                child: CircleAvatar(
                  radius: Constants.screenWidth * 0.250,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      width: screenWidth * 0.4,
                      height: screenWidth * 0.4,
                      fit: BoxFit.cover,
                      imageUrl: user.image,
                      placeholder:
                          (context, url) => const CircularProgressIndicator(),
                      errorWidget:
                          (context, url, error) => const Icon(
                            Icons.account_circle,
                            size: 60,
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Email
              Text(
                user.email,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // About Section
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          user.about.isNotEmpty
                              ? user.about
                              : "No bio available",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // "Joined On" Section
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event, color: Colors.blueAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Joined on ${CommonUtils.getLastMessageTime(context: context, time: user.createAt, showYear: true)}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ElevatedButton.icon(
                  //   onPressed: () {
                  //     // TODO: Implement edit profile functionality
                  //   },
                  //   icon: const Icon(Icons.edit_note),
                  //   label: const Text("Edit Profile"),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.blueAccent,
                  //     padding: const EdgeInsets.symmetric(
                  //       horizontal: 20,
                  //       vertical: 12,
                  //     ),
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(user: user),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Message",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20), // Ensuring enough spacing at bottom
            ],
          ),
        ),
      ),
    );
  }
}
