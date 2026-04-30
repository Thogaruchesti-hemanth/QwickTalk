import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/message.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  final Function(Message)? onReply;

  const MessageCard({super.key, required this.message, this.onReply});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.currentUser?.uid == widget.message.fromId;
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 500 && widget.onReply != null) {
          HapticFeedback.mediumImpact();
          widget.onReply!(widget.message);
        }
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showReactionDialog();
      },
      child: isMe ? _myMessage() : _senderMessage(),
    );
  }

  Widget _myMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.message.repliedTo.isNotEmpty) _buildReplyQuote(true),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF7C3AED),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4),
              ),
            ),
            child: _messageContent(Colors.white),
          ),
          _statusRow(true),
        ],
      ),
    );
  }

  Widget _senderMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.message.repliedTo.isNotEmpty) _buildReplyQuote(false),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20),
                bottomRight: Radius.circular(20), bottomLeft: Radius.circular(4),
              ),
            ),
            child: _messageContent(const Color(0xFF0F172A)),
          ),
          _statusRow(false),
        ],
      ),
    );
  }

  Widget _buildReplyQuote(bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(8),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF7C3AED).withOpacity(0.1) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: const Color(0xFF7C3AED), width: 3)),
      ),
      child: Text(widget.message.repliedTo, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isMe ? const Color(0xFF7C3AED) : Colors.black54)),
    );
  }

  Widget _messageContent(Color textColor) {
    final msg = widget.message.msg;
    final bool isTooLong = msg.length > 400 || '\n'.allMatches(msg).length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.type == Type.text)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isTooLong && !_isExpanded 
                  ? "${msg.split('\n').take(6).join('\n').substring(0, msg.length > 400 ? 400 : null)}..." 
                  : msg,
                softWrap: true,
                style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500),
              ),
              if (isTooLong)
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _isExpanded ? "Show Less" : "Read More",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: textColor.withOpacity(0.8)),
                    ),
                  ),
                ),
            ],
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(imageUrl: widget.message.msg, placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (widget.message.reaction.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)]),
              child: Text(widget.message.reaction, style: const TextStyle(fontSize: 12)),
            ),
          ),
      ],
    );
  }

  Widget _statusRow(bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            CommonUtils.getFormattedTime(context: context, time: widget.message.sent),
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              widget.message.read.isEmpty ? Icons.done : Icons.done_all,
              size: 14,
              color: widget.message.read.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF7C3AED),
            ),
          ],
        ],
      ),
    );
  }

  void _showReactionDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        elevation: 0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((e) => Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  APIs.addMessageReaction(widget.message, e);
                  Navigator.pop(context);
                },
                child: Text(e, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26)),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
