import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/screens/archived_chats_screen.dart';
import 'package:chat_app/screens/chat_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:shimmer/shimmer.dart';

import '../utils/dailogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;
  ChatUser? _selectedUser; 
  bool _isMeLoaded = false;
  
  final Set<String> _selectedUserIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadMe();

    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) APIs.updateActiveStatus(true);
        if (message.toString().contains('pause')) APIs.updateActiveStatus(false);
      }
      return Future.value(message);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    await APIs.getSelfInfo();
    if (mounted) setState(() => _isMeLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 900;
        
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            floatingActionButton: !isWideScreen && !_isSelectionMode ? FloatingActionButton(
              onPressed: _addChatUserDialog,
              backgroundColor: const Color(0xFF7C3AED),
              elevation: 4,
              child: const Icon(FeatherIcons.plus, color: Colors.white),
            ) : null,
            body: isWideScreen ? _buildWebLayout(constraints.maxWidth, constraints.maxHeight) : _buildMobileLayout(),
          ),
        );
      },
    );
  }

  Widget _buildWebLayout(double width, double height) {
    return Row(
      children: [
        Container(
          width: width * 0.3,
          constraints: const BoxConstraints(minWidth: 350, maxWidth: 450),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              _buildWebHeader(),
              _buildSearchBar(),
              _buildActiveNowBar(),
              _buildCategoryTabs(),
              Expanded(child: _buildChatList(isWeb: true)),
            ],
          ),
        ),
        Expanded(
          child: _selectedUser != null
              ? ChatScreen(
                  key: ValueKey(_selectedUser!.id),
                  user: _selectedUser!, 
                  isWeb: true
                )
              : _buildNoChatSelected(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildDefaultAppBar(),
      body: Column(
        children: [
          if (!_isSearching && !_isSelectionMode) _buildActiveNowBar(),
          Expanded(child: _buildChatList(isWeb: false)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildDefaultAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 70,
      title: _isSearching 
          ? _buildSearchField() 
          : const Text('Qwick Talk', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1.5, fontSize: 24)),
      actions: [
        IconButton(
          onPressed: () => setState(() => _isSearching = !_isSearching), 
          icon: Icon(_isSearching ? CupertinoIcons.clear_circled_solid : FeatherIcons.search, color: const Color(0xFF64748B))
        ),
        PopupMenuButton<String>(
          icon: const Icon(FeatherIcons.moreVertical, color: Color(0xFF64748B)),
          onSelected: (value) {
            if (value == 'archived') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedChatsScreen()));
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'archived',
              child: Row(
                children: [
                  Icon(FeatherIcons.archive, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 12),
                  Text("Archived Chats"),
                ],
              ),
            ),
          ],
        ),
        _buildMobileProfileButton(),
      ],
      bottom: _isSearching ? null : _buildCategoryTabs(),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF7C3AED),
      elevation: 0,
      leading: IconButton(
        onPressed: () => setState(() {
          _isSelectionMode = false;
          _selectedUserIds.clear();
        }),
        icon: const Icon(FeatherIcons.x, color: Colors.white),
      ),
      title: Text('${_selectedUserIds.length} selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      actions: [
        IconButton(
          onPressed: () async {
            for (var id in _selectedUserIds) {
              final user = _list.firstWhere((u) => u.id == id);
              await APIs.archiveChat(user);
            }
            setState(() {
              _isSelectionMode = false;
              _selectedUserIds.clear();
            });
          },
          icon: const Icon(FeatherIcons.archive, color: Colors.white),
        ),
        IconButton(
          onPressed: () async {
            final confirm = await Dialogs.showConfirmationDialog(context, 'Delete', 'Delete selected chats?');
            if (confirm == true) {
              for (var id in _selectedUserIds) {
                final user = _list.firstWhere((u) => u.id == id);
                await APIs.deleteChat(user);
              }
              setState(() {
                _isSelectionMode = false;
                _selectedUserIds.clear();
              });
            }
          },
          icon: const Icon(FeatherIcons.trash2, color: Colors.white),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildCategoryTabs() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'ALL CHATS'),
            Tab(text: 'UNREAD'),
            Tab(text: 'ONLINE'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveNowBar() {
    if (_tabController.index == 1 || _tabController.index == 2) return const SizedBox();

    return StreamBuilder(
      stream: APIs.getMyUsersId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final userIds = snapshot.data?.docs.map((e) => e.id).toList() ?? [];
        if (userIds.isEmpty) return const SizedBox();

        return StreamBuilder(
          stream: APIs.getAllUsers(userIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final fullList = snapshot.data?.docs
                .map((e) => ChatUser.fromJson(e.data() as Map<String, dynamic>))
                .where((u) => u.isOnline)
                .toList() ?? [];

            if (fullList.isEmpty) return const SizedBox();

            return FutureBuilder<List<Widget>>(
              future: _buildFilteredActiveItems(fullList),
              builder: (context, itemsSnapshot) {
                if (!itemsSnapshot.hasData || itemsSnapshot.data!.isEmpty) return const SizedBox();
                
                return SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: itemsSnapshot.data!,
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  Future<List<Widget>> _buildFilteredActiveItems(List<ChatUser> users) async {
    List<Widget> items = [];
    for (var user in users) {
      final snapshot = await APIs.fireStore.collection('chats/${APIs.getConversationID(user.id)}/messages').limit(1).get();
      final hasMessages = snapshot.docs.isNotEmpty;

      if (!hasMessages) {
        items.add(
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF7C3AED), width: 2)
                      ),
                      child: Hero(
                        tag: 'active_${user.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            width: 44,
                            height: 44,
                            imageUrl: user.image,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2)
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.name.split(' ').first,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                )
              ],
            ),
          )
        );
      }
    }
    return items;
  }

  Widget _buildMobileProfileButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: _isMeLoaded ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: APIs.me))) : null, 
        icon: _isMeLoaded 
            ? Hero(
                tag: 'my_profile',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CachedNetworkImage(
                    width: 30,
                    height: 30,
                    imageUrl: APIs.me.image,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(FeatherIcons.user, color: Color(0xFF64748B)),
                  ),
                ),
              )
            : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)))
      ),
    );
  }

  Widget _buildWebHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          _isMeLoaded 
              ? InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: APIs.me))),
                  child: Hero(
                    tag: 'my_profile_web',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CachedNetworkImage(
                        width: 44,
                        height: 44,
                        imageUrl: APIs.me.image,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const CircleAvatar(radius: 22, child: Icon(Icons.person)),
                      ),
                    ),
                  ),
                )
              : const CircleAvatar(radius: 22, child: Icon(Icons.person)),
          const SizedBox(width: 12),
          const Text("My Chats", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A))),
          const Spacer(),
          IconButton(onPressed: _addChatUserDialog, icon: const Icon(FeatherIcons.plusCircle, color: Color(0xFF7C3AED))),
          IconButton(
            onPressed: _isMeLoaded ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: APIs.me))) : null, 
            icon: const Icon(FeatherIcons.settings, size: 20, color: Color(0xFF64748B))
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 45,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
        child: TextField(
          onChanged: _filterUsers,
          decoration: const InputDecoration(
            border: InputBorder.none, 
            hintText: 'Search conversations...', 
            prefixIcon: Icon(FeatherIcons.search, size: 16, color: Color(0xFF94A3B8)),
            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)
          ),
        ),
      ),
    );
  }

  Widget _buildChatList({required bool isWeb}) {
    return StreamBuilder(
      stream: APIs.getMyUsersId(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return _buildShimmerLoading();
        final userIds = snapshot.data?.docs.map((e) => e.id).toList() ?? [];
        if (userIds.isEmpty) return _buildEmptyState();

        return StreamBuilder(
          stream: APIs.getAllUsers(userIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return _buildShimmerLoading();
            _list = snapshot.data?.docs.map((e) => ChatUser.fromJson(e.data() as Map<String, dynamic>)).toList() ?? [];
            
            List<ChatUser> displayList = _isSearching ? _searchList : _list;
            
            if (!_isSearching) {
              if (_tabController.index == 2) {
                displayList = _list.where((u) => u.isOnline).toList();
              }
            }

            return RefreshIndicator(
              onRefresh: () async => APIs.getSelfInfo(),
              color: const Color(0xFF7C3AED),
              child: ListView.builder(
                itemCount: displayList.length,
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemBuilder: (context, index) {
                  final user = displayList[index];
                  final isSelected = _selectedUserIds.contains(user.id);
                  
                  return ChatUserCard(
                    user: user, 
                    isWeb: isWeb,
                    onTap: _isSelectionMode ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserIds.remove(user.id);
                          if (_selectedUserIds.isEmpty) _isSelectionMode = false;
                        } else {
                          _selectedUserIds.add(user.id);
                        }
                      });
                    } : (isWeb ? () {
                      if (mounted) setState(() => _selectedUser = user);
                    } : null),
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      setState(() {
                        _isSelectionMode = true;
                        _selectedUserIds.add(user.id);
                      });
                    },
                    isSelected: isSelected,
                    tabIndex: _tabController.index,
                    isSearching: _isSearching,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 12, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: double.infinity, height: 10, color: Colors.white),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoChatSelected() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.08), blurRadius: 40)]),
              child: const Icon(FeatherIcons.messageCircle, size: 60, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 24),
            const Text("Qwick Talk Web", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text("Pick a conversation to start chatting.", style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  void _filterUsers(String val) {
    _searchList.clear();
    _isSearching = val.isNotEmpty;
    for (var i in _list) {
      if (i.name.toLowerCase().contains(val.toLowerCase()) || i.email.toLowerCase().contains(val.toLowerCase())) {
        _searchList.add(i);
      }
    }
    setState(() {});
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: _filterUsers,
      autofocus: true,
      style: const TextStyle(fontSize: 16),
      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search...'),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No chats found", style: TextStyle(color: Colors.grey)));
  }

  void _addChatUserDialog() {
    String email = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(FeatherIcons.userPlus, color: Color(0xFF7C3AED), size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add New Contact',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the email address of the person you want to connect with.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              keyboardType: TextInputType.emailAddress,
              onChanged: (v) => email = v,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'email@example.com',
                prefixIcon: const Icon(FeatherIcons.mail, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (email.trim().isNotEmpty) {
                      Navigator.pop(context);
                      bool success = await APIs.addChatUser(email.trim());
                      if (!success && mounted) {
                        Dialogs.showSnackBar(context, 'User does not exist!');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }
}
