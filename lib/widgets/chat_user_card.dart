import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/utils/constants.dart';
import 'package:chat_app/widgets/profile_dialog.dart';
import 'package:flutter/material.dart';

import '../models/chat_user.dart';
import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      margin: EdgeInsets.symmetric(
        horizontal: Constants.screenWidth * 0.04,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        splashColor: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data?.docs;
            final list =
                data
                    ?.map(
                      (e) => Message.fromJson(e.data() as Map<String, dynamic>),
                    )
                    .toList() ??
                [];

            // Local variables to hold message & unread status
            Message? lastMessage;
            bool hasUnread = false;

            if (list.isNotEmpty) {
              lastMessage = list[0];
              hasUnread =
                  lastMessage.read.isEmpty &&
                  lastMessage.fromId != APIs.user.uid;
            }

            return ListTile(
              leading: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ProfileDialog(user: widget.user),
                  );
                },
                child: CircleAvatar(
                  radius: Constants.screenWidth * 0.075,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: CachedNetworkImageProvider(
                    widget.user.image,
                  ),
                ),
              ),
              title: Text(
                widget.user.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                lastMessage != null
                    ? lastMessage.type == Type.image
                        ? '📷 Image'
                        : lastMessage.msg
                    : widget.user.about,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.black54),
              ),
              trailing:
                  lastMessage == null
                      ? null
                      : hasUnread
                      ? Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "1+",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                      : Text(
                        CommonUtils.getLastMessageTime(
                          context: context,
                          time: lastMessage.sent,
                        ),
                        style: TextStyle(color: Colors.black54),
                      ),
            );
          },
        ),
      ),
    );
  }
}
