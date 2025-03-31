import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:chat_app/utils/constants.dart';
import 'package:chat_app/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../api/apis.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];
  final _textController = TextEditingController();
  bool _showEmoji = false, _isUploading = false;

  @override
  void initState() {
    super.initState();
    APIs.getAllMessages(widget.user).listen((snapshot) {
      for (var doc in snapshot.docs) {
        Message message = Message.fromJson(doc.data());

        if (message.read == null || message.read!.isEmpty) {
          APIs.updateMessageReadStatus(message);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: SafeArea(
            child: Scaffold(
              backgroundColor: Color(0xFFF3F3F3),
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(Constants.screenHeight * .09),
                child: AppBar(
                  leading: SizedBox.shrink(),
                  flexibleSpace: _appBar(),
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: StreamBuilder(
                      stream: APIs.getAllMessages(widget.user),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            return const SizedBox();
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            if (data != null && data.isNotEmpty) {
                              CommonUtils.prints(
                                'Data: ${jsonEncode(data[0].data())}',
                              );
                              _list =
                                  data
                                      .map((e) => Message.fromJson(e.data()))
                                      .toList();
                            } else {
                              _list = [];
                            }

                            return _list.isNotEmpty
                                ? ListView.builder(
                                  reverse: true,
                                  itemCount: _list.length,
                                  padding: EdgeInsets.only(
                                    top: Constants.screenWidth * 0.2,
                                  ),
                                  physics: const BouncingScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return MessageCard(message: _list[index]);
                                  },
                                )
                                : const Center(
                                  child: Text(
                                    'Say Hii! ',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                );
                        }
                      },
                    ),
                  ),
                  if (_isUploading)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 20,
                        ),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  _chatInput(),
                  if (_showEmoji)
                    SizedBox(
                      height: Constants.screenHeight * 0.35,
                      child: EmojiPicker(
                        textEditingController: _textController,
                        config: Config(
                          height: 256,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: Colors.lightBlueAccent.shade100,
                            emojiSizeMax: 28 * (Platform.isIOS ? 1.20 : 1.0),
                          ),
                          searchViewConfig: SearchViewConfig(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewProfileScreen(user: widget.user),
          ),
        );
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  Constants.screenHeight * 0.05,
                ),
                child: CachedNetworkImage(
                  width: Constants.screenWidth * 0.12,
                  height: Constants.screenHeight * 0.06,
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  placeholder:
                      (context, url) => const CircularProgressIndicator(),
                  errorWidget:
                      (context, url, error) => const CircleAvatar(
                        child: Icon(CupertinoIcons.person),
                      ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : CommonUtils.getLastActiveTime(
                              context: context,
                              lastActive: list[0].lastActive,
                            )
                        : CommonUtils.getLastActiveTime(
                          context: context,
                          lastActive: widget.user.lastActive,
                        ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: Constants.screenWidth * 0.02,
        horizontal: Constants.screenHeight * 0.02,
      ),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  if (!kIsWeb)
                    IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _showEmoji = !_showEmoji;
                        });
                      },
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: Colors.blueAccent,
                        size: 26,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextField(
                        controller: _textController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        onTap: () {
                          if (_showEmoji)
                            setState(() {
                              _showEmoji = !_showEmoji;
                            });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Type Something...',
                          hintStyle: TextStyle(color: Colors.blueAccent),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  // IconButton(
                  //   onPressed: () async {
                  //     final ImagePicker picker = ImagePicker();
                  //     final List<XFile> images = await picker.pickMultiImage(
                  //       imageQuality: 70,
                  //     );
                  //     for (var i in images) {
                  //       CommonUtils.prints(
                  //         'Image Path: ${i.path} -- MimeType: ${i.mimeType}',
                  //       );
                  //       setState(() {
                  //         _isUploading = true;
                  //       });
                  //       await APIs.sendChatImage(widget.user, File(i.path));
                  //       setState(() {
                  //         _isUploading = false;
                  //       });
                  //     }
                  //     if (images.isNotEmpty) {}
                  //   },
                  //   icon: const Icon(
                  //     Icons.image,
                  //     color: Colors.blueAccent,
                  //     size: 26,
                  //   ),
                  // ),
                  // IconButton(
                  //   onPressed: () async {
                  //     final ImagePicker picker = ImagePicker();
                  //     final XFile? image = await picker.pickImage(
                  //       source: ImageSource.camera,
                  //       imageQuality: 70,
                  //     );
                  //     if (image != null) {
                  //       CommonUtils.prints(
                  //         'Image Path: ${image.path} -- MimeType: ${image.mimeType}',
                  //       );
                  //       await APIs.sendChatImage(widget.user, File(image.path));
                  //     }
                  //   },
                  //   icon: const Icon(
                  //     Icons.camera_alt_rounded,
                  //     color: Colors.blueAccent,
                  //     size: 26,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          MaterialButton(
            shape: const CircleBorder(),
            minWidth: 0,
            padding: const EdgeInsets.all(10),
            color: Colors.green,
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                if (_list.isEmpty) {
                  APIs.sendFirstMessage(
                    widget.user,
                    _textController.text,
                    Type.text,
                  );
                } else {
                  APIs.sendMessage(
                    widget.user,
                    _textController.text,
                    Type.text,
                  );
                }
                _textController.clear();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Icon(Icons.send, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
