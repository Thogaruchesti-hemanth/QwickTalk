import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/view_profile_screen.dart';
import 'package:chat_app/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  final bool isWeb;

  const ChatScreen({super.key, required this.user, this.isWeb = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const _channel = MethodChannel('com.hemanth.qwicktalk/security');

  List<Message> _list = [];
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _showEmoji = false, _isUploading = false, _isSearching = false;
  String _searchQuery = '';
  Message? _replyMessage;
  Timer? _typingTimer;
  bool _isWindowFocused = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _toggleSecureScreen(true);
    
    APIs.getAllMessages(widget.user).listen((snapshot) {
      for (var doc in snapshot.docs) {
        Message message = Message.fromJson(doc.data());
        if (message.read.isEmpty && message.fromId != APIs.currentUser!.uid) {
          APIs.updateMessageReadStatus(message);
        }
      }
      _scrollToBottom();
    });
  }

  Future<void> _toggleSecureScreen(bool enabled) async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await _channel.invokeMethod('secureScreen', enabled);
      } catch (e) {
        debugPrint('Failed to toggle secure screen: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) {
      setState(() {
        _isWindowFocused = state == AppLifecycleState.resumed;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTyping() {
    APIs.updateTypingStatus(widget.user.id, true);
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      APIs.updateTypingStatus(widget.user.id, false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _toggleSecureScreen(false);
    _typingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    APIs.updateTypingStatus(widget.user.id, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        canPop: !_showEmoji,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
        },
        child: Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              extendBodyBehindAppBar: true,
              appBar: _buildAppBar(),
              body: Column(
                children: [
                  Expanded(
                    child: StreamBuilder(
                      stream: APIs.getAllMessages(widget.user),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
                        
                        final data = snapshot.data?.docs;
                        _list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
                        
                        final displayList = _isSearching 
                            ? _list.where((m) => m.msg.toLowerCase().contains(_searchQuery.toLowerCase())).toList()
                            : _list;

                        return displayList.isNotEmpty
                            ? ListView.builder(
                                reverse: true,
                                controller: _scrollController,
                                itemCount: displayList.length,
                                padding: EdgeInsets.only(top: kToolbarHeight + 60, bottom: 16),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return MessageCard(
                                    message: displayList[index],
                                    onReply: (msg) => setState(() => _replyMessage = msg),
                                  );
                                },
                              )
                            : _buildSayHi();
                      },
                    ),
                  ),
                  if (_isUploading) const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF7C3AED)),
                  _buildReplyPreview(),
                  SafeArea(
                    top: false,
                    child: _chatInput(),
                  ),
                  if (_showEmoji) _buildEmojiPicker(),
                ],
              ),
            ),
            
            // WEB PROTECTION OVERLAY (Blurs content if window loses focus)
            if (kIsWeb && !_isWindowFocused)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Text(
                        "Content Protected\nReturn to tab to view",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 20),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            toolbarHeight: kToolbarHeight + 20,
            title: _isSearching ? _buildSearchField() : _appBarContent(),
            actions: [
              IconButton(
                onPressed: () => setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) _searchQuery = '';
                }),
                icon: Icon(_isSearching ? Icons.close : FeatherIcons.search, size: 20, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      onChanged: (val) => setState(() => _searchQuery = val),
      style: const TextStyle(fontSize: 16, color: Color(0xFF0F172A)),
      decoration: const InputDecoration(hintText: 'Search in chat...', border: InputBorder.none),
    );
  }

  Widget _appBarContent() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ViewProfileScreen(user: widget.user))),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FeatherIcons.chevronLeft, color: Color(0xFF1E293B)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Hero(
            tag: 'profile_${widget.user.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CachedNetworkImage(
                width: 36, height: 36, imageUrl: widget.user.image, fit: BoxFit.cover,
                errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder(
              stream: APIs.getTypingStatus(widget.user),
              builder: (context, snapshot) {
                bool isTyping = false;
                if (snapshot.hasData && snapshot.data!.data() != null) {
                  isTyping = snapshot.data!.data()![widget.user.id] ?? false;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.user.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Text(
                      isTyping ? 'typing...' : (widget.user.isOnline ? 'Online' : 'Offline'),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isTyping ? const Color(0xFF7C3AED) : (widget.user.isOnline ? Colors.green : Colors.grey)),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyMessage == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Color(0xFF7C3AED), width: 4))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replying to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED))),
                Text(_replyMessage!.msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          IconButton(onPressed: () => setState(() => _replyMessage = null), icon: const Icon(Icons.close, size: 18)),
        ],
      ),
    );
  }

  Widget _chatInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: IconButton(
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() => _showEmoji = !_showEmoji);
              },
              icon: const Icon(FeatherIcons.smile, color: Color(0xFF64748B), size: 24),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
              child: TextField(
                controller: _textController,
                maxLines: 5,
                minLines: 1,
                onChanged: (_) => _onTyping(),
                onTap: () { if (_showEmoji) setState(() => _showEmoji = false); },
                decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () {
                if (_textController.text.trim().isNotEmpty) {
                  HapticFeedback.lightImpact();
                  APIs.sendMessage(widget.user, _textController.text, Type.text, repliedTo: _replyMessage?.msg ?? '');
                  _textController.clear();
                  setState(() => _replyMessage = null);
                  APIs.updateTypingStatus(widget.user.id, false);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle),
                child: const Icon(FeatherIcons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 300,
      child: EmojiPicker(
        textEditingController: _textController,
        config: const Config(emojiViewConfig: EmojiViewConfig(backgroundColor: Color(0xFFF8FAFC))),
      ),
    );
  }

  Widget _buildSayHi() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('Say Hi to ${widget.user.name}!', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
