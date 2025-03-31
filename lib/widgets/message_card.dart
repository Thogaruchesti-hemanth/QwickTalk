import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/message.dart';
import '../utils/dailogs.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({super.key, required this.message});

  final Message message;

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
      onLongPress: () => _showBottomSheet(isMe),
      child: isMe ? _greenMessage() : _blueMessage(),
    );
  }

  Widget _greenMessage() {
    if (widget.message.read.isEmpty && widget.message.fromId != APIs.user.uid) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return _buildMessageContainer(
      alignment: Alignment.centerRight,
      color: Colors.green.shade300,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
      ),
      isMe: true,
    );
  }

  Widget _blueMessage() {
    return _buildMessageContainer(
      alignment: Alignment.centerLeft,
      color: Colors.blue.shade300,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      isMe: false,
    );
  }

  Widget _buildMessageContainer({
    required Alignment alignment,
    required Color color,
    required BorderRadius borderRadius,
    required bool isMe,
  }) {
    final formattedTime = CommonUtils.getFormattedTime(
      context: context,
      time: widget.message.sent,
    );

    return Align(
      alignment: alignment,
      child: Container(
        padding: EdgeInsets.all(12),
        margin: EdgeInsets.symmetric(
          horizontal: Constants.screenWidth * .02,
          vertical: Constants.screenHeight * .005,
        ),
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            widget.message.type == Type.text
                ? Text(
                  widget.message.msg,
                  style: TextStyle(fontSize: 16, color: Colors.white),
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    width: Constants.screenWidth * 0.4,
                    height: Constants.screenHeight * 0.2,
                    fit: BoxFit.cover,
                    imageUrl: widget.message.msg,
                    errorWidget:
                        (context, url, error) => const CircleAvatar(
                          child: Icon(Icons.image, size: 50),
                        ),
                  ),
                ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                if (isMe) ...[
                  SizedBox(width: 5),
                  Icon(
                    widget.message.read.isEmpty
                        ? Icons
                            .done // White single tick
                        : Icons.done_all, // Blue double tick
                    size: 16,
                    color:
                        widget.message.read.isEmpty
                            ? Colors
                                .white // White tick for unread
                            : Colors.blue, // Blue tick for read
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [
            if (widget.message.type == Type.text)
              _OptionItem(
                icon: Icon(Icons.copy, color: Colors.blue, size: 26),
                name: 'Copy Text',
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.message.msg),
                  );
                  Navigator.pop(context);
                  Dialogs.showSnackBar(context, 'Text Copied');
                },
              ),
            if (widget.message.type != Type.text)
              _OptionItem(
                icon: Icon(Icons.download, color: Colors.blue, size: 26),
                name: 'Save Image',
                onTap: () {},
              ),
            if (isMe) _buildDivider(),
            if (widget.message.type == Type.text && isMe)
              _OptionItem(
                icon: Icon(Icons.edit, color: Colors.blue, size: 26),
                name: 'Edit Message',
                onTap: () {
                  Navigator.pop(context);
                  _showMessageUpdateDialog();
                },
              ),
            if (isMe)
              _OptionItem(
                icon: Icon(Icons.delete, color: Colors.red, size: 26),
                name: 'Delete Message',
                onTap: () {
                  _deleteMessage(context);
                },
              ),
            _buildDivider(),
            _OptionItem(
              icon: Icon(Icons.access_time, color: Colors.blue, size: 26),
              name:
                  'Sent At: ${CommonUtils.getMessageTime(context: context, time: widget.message.sent)}',
              onTap: () {},
            ),
            _OptionItem(
              icon: Icon(Icons.visibility, color: Colors.green, size: 26),
              name:
                  widget.message.read.isEmpty
                      ? 'Not Seen yet'
                      : 'Read At: ${CommonUtils.getMessageTime(context: context, time: widget.message.read)}',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  void _deleteMessage(BuildContext context) async {
    bool? confirm = await Dialogs.showConfirmationDialog(
      context,
      "Delete Message",
      "Are you sure you want to delete this message?",
    );

    if (confirm == true) {
      Navigator.pop(context);
      await APIs.deleteMessage(widget.message);
    }
  }

  Widget _buildDivider() {
    return Divider(color: Colors.black54, endIndent: 20, indent: 20);
  }

  void _showMessageUpdateDialog() {
    String updateMsg = widget.message.msg;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.message, color: Colors.blue, size: 28),
                Text('Update Message'),
              ],
            ),
            content: TextFormField(
              initialValue: updateMsg,
              maxLines: null,
              onChanged: (value) => updateMsg = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: Colors.blue)),
              ),
              TextButton(
                onPressed: () {
                  if (updateMsg.trim().isNotEmpty) {
                    APIs.updateMessage(widget.message, updateMsg);
                    Navigator.pop(context);
                  }
                },
                child: Text('Update', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _OptionItem({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
          left: Constants.screenWidth * .05,
          top: Constants.screenHeight * .015,
          bottom: Constants.screenHeight * .015,
        ),
        child: Row(
          children: [
            icon,
            Flexible(
              child: Text(
                '      $name',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
