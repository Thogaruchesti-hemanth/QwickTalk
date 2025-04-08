import 'package:chat_app/api/apis.dart';
import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/widgets/chat_user_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import '../utils/dailogs.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    SystemChannels.lifecycle.setMessageHandler((message) {
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message?.contains('pause') ?? false) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  void dispose() {
    APIs.updateActiveStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          if (_isSearching) {
            setState(() {
              _isSearching = false;
            });
            return false;
          } else {
            return true;
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: Icon(
              FeatherIcons.messageCircle,
              size: 30,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            title:
                _isSearching
                    ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search Users...',
                        ),
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchList
                              ..clear()
                              ..addAll(
                                _list.where(
                                  (user) =>
                                      user.name.toLowerCase().contains(
                                        value.toLowerCase(),
                                      ) ||
                                      user.email.toLowerCase().contains(
                                        value.toLowerCase(),
                                      ),
                                ),
                              );
                          });
                        },
                      ),
                    )
                    : const Text(
                      'Quick Chat',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            actions: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : FeatherIcons.search,
                  size: 30,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me),
                    ),
                  );
                },
                icon: const Icon(FeatherIcons.user, size: 30),
              ),
            ],
          ),
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(child: CircularProgressIndicator());
                case ConnectionState.active:
                case ConnectionState.done:
                  final userIds =
                      snapshot.data?.docs.map((e) => e.id).toList() ?? [];
                  if (userIds.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Connections Found!',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
                  return StreamBuilder(
                    stream: APIs.getAllUsers(userIds),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;
                          _list =
                              data
                                  ?.map((e) => ChatUser.fromJson(e.data()))
                                  .toList() ??
                              [];

                          if (_list.isNotEmpty) {
                            return ListView.separated(
                              itemCount:
                                  _isSearching
                                      ? _searchList.length
                                      : _list.length,
                              padding: const EdgeInsets.only(top: 10),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return ChatUserCard(
                                  user:
                                      _isSearching
                                          ? _searchList[index]
                                          : _list[index],
                                );
                              },
                              separatorBuilder:
                                  (context, index) => const SizedBox(height: 1),
                            );
                          } else {
                            return const Center(
                              child: Text(
                                'No Connections Found!',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  );
              }
            },
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: _addChatUserDialog,
            child: const Icon(
              Icons.person_add_alt_1,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _addChatUserDialog() {
    String email = '';
    bool isButtonEnabled = false;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.person_add_alt_1, color: Colors.blue, size: 28),
                    SizedBox(width: 10),
                    Text('Add User'),
                  ],
                ),
                content: TextField(
                  onChanged: (value) {
                    setState(() {
                      email = value.trim();
                      isButtonEnabled = email.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        isButtonEnabled
                            ? () async {
                              Navigator.pop(context);
                              await APIs.addChatUser(email).then((exists) {
                                Dialogs.showSnackBar(
                                  context,
                                  exists
                                      ? 'User added successfully'
                                      : 'User does not exist',
                                );
                              });
                            }
                            : null,
                    child: const Text('Add'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
