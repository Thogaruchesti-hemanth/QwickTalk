import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/widgets/profile_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../models/chat_user.dart';
import '../screens/chat_screen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  final bool isWeb;
  final bool isArchivedScreen;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // Added missing parameter
  final bool isSelected;
  final int tabIndex;
  final bool isSearching;

  const ChatUserCard({
    super.key,
    required this.user,
    this.isWeb = false,
    this.isArchivedScreen = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.tabIndex = 0,
    this.isSearching = false,
  });

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
      lowerBound: 0.8,
      upperBound: 1.2,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: APIs.getLastMessage(widget.user),
      builder: (context, snapshot) {
        final data = snapshot.data?.docs;
        final list = data?.map((e) => Message.fromJson(e.data() as Map<String, dynamic>)).toList() ?? [];

        Message? lastMessage;
        bool hasUnread = false;

        if (list.isNotEmpty) {
          lastMessage = list[0];
          hasUnread = lastMessage.read.isEmpty && lastMessage.fromId != APIs.currentUser?.uid;
        }

        // Apply Tab Filtering inside ChatUserCard to support localized updates
        if (!widget.isSearching) {
          if (widget.tabIndex == 1 && !hasUnread) return const SizedBox();
          if (widget.tabIndex == 0 && lastMessage == null && !widget.isArchivedScreen) return const SizedBox();
        }

        return Dismissible(
          key: Key(widget.user.id),
          direction: DismissDirection.horizontal,
          background: _buildSwipeBackground(
            widget.isArchivedScreen ? FeatherIcons.rotateCcw : FeatherIcons.archive,
            const Color(0xFF22C55E),
            Alignment.centerLeft,
          ),
          secondaryBackground: _buildSwipeBackground(
            FeatherIcons.trash2,
            const Color(0xFFEF4444),
            Alignment.centerRight,
          ),
          onDismissed: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              if (widget.isArchivedScreen) {
                await APIs.unarchiveChat(widget.user);
              } else {
                await APIs.archiveChat(widget.user);
              }
            } else {
              await APIs.deleteChat(widget.user);
            }
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isHovered || widget.isSelected ? const Color(0xFFF1F5F9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (_isHovered || widget.isSelected)
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap ?? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
                  );
                },
                onLongPress: widget.onLongPress,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: _buildAvatar(hasUnread),
                    title: Text(
                      widget.user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage != null
                          ? lastMessage.type == Type.image
                              ? '📷 Image'
                              : lastMessage.msg
                          : widget.user.about,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: hasUnread ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    trailing: _buildTrailing(lastMessage, hasUnread),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSwipeBackground(IconData icon, Color color, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildAvatar(bool hasUnread) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            showDialog(context: context, builder: (_) => ProfileDialog(user: widget.user));
          },
          child: Hero(
            tag: 'profile_${widget.user.id}',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasUnread ? const Color(0xFF7C3AED) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  width: 50,
                  height: 50,
                  imageUrl: widget.user.image,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),
            ),
          ),
        ),
        if (widget.user.isOnline)
          Positioned(
            bottom: 2,
            right: 2,
            child: ScaleTransition(
              scale: _pulseController,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget? _buildTrailing(Message? lastMessage, bool hasUnread) {
    if (lastMessage == null) return null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          CommonUtils.getLastMessageTime(context: context, time: lastMessage.sent),
          style: TextStyle(
            fontSize: 11,
            color: hasUnread ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (hasUnread)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              "NEW",
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}
