import 'dart:convert';
import 'dart:io';

import 'package:chat_app/models/chat_user.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/utils/common_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as google_auth;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'notification_config.dart';

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static FirebaseDatabase database = FirebaseDatabase.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  static late ChatUser me;

  static User? get currentUser => auth.currentUser;

  static Future<void> getFirebaseMessageToken() async {
    await messaging.requestPermission();
    String? token = await messaging.getToken(vapidKey: dotenv.get('FCM_VAPID_KEY'));
    if (token != null) {
      me.pushToken = token;
      await updateActiveStatus(true);
      CommonUtils.prints('Push token: $token');
    }
  }

  // --- MODERN FCM V1 PUSH NOTIFICATION (SERVERLESS) ---
  static Future<String> _getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": NotificationConfig.projectId,
      "private_key": NotificationConfig.privateKey.replaceAll(r'\n', '\n'),
      "client_email": NotificationConfig.clientEmail,
      "client_id": NotificationConfig.clientId,
    };

    List<String> scopes = ["https://www.googleapis.com/auth/userinfo.email", "https://www.googleapis.com/auth/firebase.messaging"];

    final client = await google_auth.clientViaServiceAccount(
      google_auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    return client.credentials.accessToken.data;
  }

  static Future<void> sendPushNotification(ChatUser chatUser, String msg) async {
    if (chatUser.pushToken.isEmpty) {
      CommonUtils.prints('Notification skipped: No push token for user');
      return;
    }

    try {
      final bearerToken = await _getAccessToken();
      final projectId = NotificationConfig.projectId;

      final body = {
        "message": {
          "token": chatUser.pushToken,
          "notification": {
            "title": me.name, 
            "body": msg
          },
          "android": {
            "notification": {
              "channel_id": "chats",
              "priority": "high",
              "sound": "default",
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": me.id,
            "name": me.name,
            "type": "chat"
          }
        }
      };

      final res = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $bearerToken'
        },
        body: jsonEncode(body),
      );
      
      CommonUtils.prints('Notification Status: ${res.statusCode} | Response: ${res.body}');
    } catch (e) {
      CommonUtils.prints('Notification Error: $e');
    }
  }

  static Future<bool> userExists() async {
    final user = currentUser;
    if (user == null) return false;
    return (await fireStore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<bool> addChatUser(String email) async {
    final user = currentUser;
    if (user == null) return false;

    final data = await fireStore.collection('users').where('email', isEqualTo: email).get();
            
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      fireStore.collection('users').doc(user.uid).collection('my_users').doc(data.docs.first.id).set({'isArchived': false});
      return true;
    } else {
      return false;
    }
  }

  static Future<void> archiveChat(ChatUser user) async {
    await fireStore.collection('users').doc(currentUser!.uid).collection('my_users').doc(user.id).update({'isArchived': true});
  }

  static Future<void> unarchiveChat(ChatUser user) async {
    await fireStore.collection('users').doc(currentUser!.uid).collection('my_users').doc(user.id).update({'isArchived': false});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return fireStore.collection('users').doc(currentUser?.uid ?? '').collection('my_users').where('isArchived', isEqualTo: false).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getArchivedUsersId() {
    return fireStore.collection('users').doc(currentUser?.uid ?? '').collection('my_users').where('isArchived', isEqualTo: true).snapshots();
  }

  static Future<void> deleteChat(ChatUser user) async {
    await fireStore.collection('users').doc(currentUser!.uid).collection('my_users').doc(user.id).delete();
  }

  static Future<void> getSelfInfo() async {
    final user = currentUser;
    if (user == null) return;

    final userDoc = await fireStore.collection('users').doc(user.uid).get();
    if (userDoc.exists) {
      me = ChatUser.fromJson(userDoc.data()!);
      await getFirebaseMessageToken();
      await updateActiveStatus(true);
    } else {
      await createUser();
      await getSelfInfo();
    }
  }

  static Future<void> createUser() async {
    final user = currentUser;
    if (user == null) return;

    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey i'm using Quick Chat!",
      image: user.photoURL.toString(),
      createAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );

    return await fireStore.collection('users').doc(user.uid).set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(List<String> userIds) {
    return fireStore.collection('users').where('id', whereIn: userIds.isEmpty ? [''] : userIds).snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) async {
    final user = currentUser;
    if (user == null) return;

    return fireStore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  static Future<void> updateProfilePicture(File file) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final ext = file.path.split('.').last;
      final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
      await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
      me.image = await ref.getDownloadURL();
      await fireStore.collection('users').doc(user.uid).update({'image': me.image});
    } catch (e) {
      CommonUtils.prints('Profile Picture Error: $e');
    }
  }

  static Future<void> updateUserInfo() async {
    final user = currentUser;
    if (user == null) return;

    await fireStore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  static String getConversationID(String id) {
    final user = currentUser;
    if (user == null) return '';
    // Use compareTo for cross-platform consistency instead of hashCode
    final conversationID = user.uid.compareTo(id) <= 0 ? '${user.uid}_$id' : '${id}_${user.uid}';
    CommonUtils.prints('Conversation ID for $id: $conversationID');
    return conversationID;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(ChatUser user) {
    return fireStore.collection('chats/${getConversationID(user.id)}/messages').orderBy('sent', descending: true).snapshots();
  }

  static Future<void> sendMessage(ChatUser chatUser, String msg, Type type, {String repliedTo = ''}) async {
    final user = currentUser;
    if (user == null) return;

    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
      repliedTo: repliedTo,
    );
    final ref = fireStore.collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) => sendPushNotification(chatUser, type == Type.text ? msg : '📷 Image'));
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    fireStore.collection('chats/${getConversationID(message.fromId == currentUser!.uid ? message.toId : message.fromId)}/messages').doc(message.sent).update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(ChatUser user) {
    return fireStore.collection('chats/${getConversationID(user.id)}/messages').orderBy('sent', descending: true).limit(1).snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child('images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext');
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext'));
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  static Future<void> deleteMessage(Message message) async {
    await fireStore.collection('chats/${getConversationID(message.fromId == currentUser!.uid ? message.toId : message.fromId)}/messages').doc(message.sent).delete();
    if (message.type == Type.image) await storage.refFromURL(message.msg).delete();
  }

  static Future<void> updateMessage(Message message, String updatedMessage) async {
    await fireStore.collection('chats/${getConversationID(message.fromId == currentUser!.uid ? message.toId : message.fromId)}/messages').doc(message.sent).update({'msg': updatedMessage});
  }

  static Future<void> updateTypingStatus(String toId, bool isTyping) async {
    await fireStore.collection('chats').doc(getConversationID(toId)).set({currentUser!.uid: isTyping}, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getTypingStatus(ChatUser user) {
    return fireStore.collection('chats').doc(getConversationID(user.id)).snapshots();
  }

  static Future<void> addMessageReaction(Message message, String emoji) async {
    await fireStore.collection('chats/${getConversationID(message.fromId == currentUser!.uid ? message.toId : message.fromId)}/messages').doc(message.sent).update({'reaction': emoji});
  }
}
