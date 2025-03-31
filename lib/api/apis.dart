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

class APIs {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  static FirebaseDatabase database = FirebaseDatabase.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  static Future<void> getFirebaseMessageToken() async {
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    if (token != null) {
      me.pushToken = token;
      await updateActiveStatus(true);
      CommonUtils.prints('Push token: $token');
    }
  }

  static late ChatUser me;

  static User get user => auth.currentUser!;

  static Future<bool> userExists() async {
    return (await fireStore.collection('users').doc(user.uid).get()).exists;
  }

  static Future<bool> addChatUser(String email) async {
    final data =
        await fireStore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      fireStore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

  static Future<void> getSelfInfo() async {
    await fireStore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessageToken();
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  static Future<void> createUser() async {
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

    return await fireStore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return APIs.fireStore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
    List<String> userIds,
  ) {
    return APIs.fireStore
        .collection('users')
        .where('id', whereIn: userIds)
        .snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    ChatUser chatUser,
  ) {
    return APIs.fireStore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  static Future<void> updateActiveStatus(bool isOnline) {
    return APIs.fireStore.collection('users').doc(user.uid).update({
      'is_Online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  static Future<void> sendFirstMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    await fireStore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({})
        .then((value) => sendMessage(chatUser, msg, type));
  }

  static Future<void> updateUserInfo() async {
    await fireStore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // static Future<void> updateProfilePicture(File file) async {
  //   final ext = file.path.split('.').last;
  //   CommonUtils.prints('Extension:$ext');
  //   final ref = storage.ref().child('profile/pictures/${user.uid}.$ext');
  //   await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((
  //     p0,
  //   ) {
  //     CommonUtils.prints('Data Transferred: ${p0.bytesTransferred / 1000}kb');
  //   });
  //   me.image = await ref.getDownloadURL();
  //   await fireStore.collection('users').doc(user.uid).update({
  //     'image': me.image,
  //   });
  // }

  static Future<void> updateProfilePicture(File file) async {
    try {
      // Read the image file as bytes
      List<int> imageBytes = await file.readAsBytes();

      // Convert image bytes to Base64 string
      String base64Image = base64Encode(imageBytes);

      // Store the Base64 image string in Firebase Realtime Database
      await database.ref('users/${user.uid}').update({'image': base64Image});

      CommonUtils.prints('Image successfully uploaded to Realtime Database.');
    } catch (e) {
      CommonUtils.prints('Error uploading image: $e');
    }
  }

  static Future<File?> getProfilePicture() async {
    try {
      DatabaseReference ref = database.ref('users/${user.uid}/image');

      DatabaseEvent event = await ref.once();
      String? base64Image = event.snapshot.value as String?;

      if (base64Image == null) return null;

      // Convert Base64 back to bytes
      List<int> imageBytes = base64Decode(base64Image);

      // Create a temporary file
      File imageFile = File('/tmp/${user.uid}.png');
      await imageFile.writeAsBytes(imageBytes);

      return imageFile;
    } catch (e) {
      CommonUtils.prints('Error retrieving image: $e');
      return null;
    }
  }

  ///Chat Screen Realted APIs///

  static String getConversationID(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser user,
  ) {
    return APIs.fireStore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  //Chat (collection)----> Conversation_id(doc)-->messages(collection)-->message(doc)

  static Future<void> sendMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = fireStore.collection(
      'chats/${getConversationID(chatUser.id)}/messages/',
    );
    await ref.doc(time).set(message.toJson());
  }

  static Future<void> updateMessageReadStatus(Message message) async {
    fireStore
        .collection('chats/${getConversationID(message.fromId)}/messages')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static Stream<QuerySnapshot> getLastMessage(ChatUser user) {
    return APIs.fireStore
        .collection('chats/${getConversationID(user.id)}/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    final ext = file.path.split('.').last;
    final ref = storage.ref().child(
      'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    await ref.putFile(file, SettableMetadata(contentType: 'image/$ext')).then((
      p0,
    ) {
      CommonUtils.prints('Data Transferred: ${p0.bytesTransferred / 1000}kb');
    });

    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  /// Delete a message from Firestore and Storage (if it's an image)
  static Future<void> deleteMessage(Message message) async {
    await fireStore
        .collection('chats/${getConversationID(message.toId)}/messages')
        .doc(message.sent)
        .delete();
    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  /// Update an existing message
  static Future<void> updateMessage(
    Message message,
    String updatedMessage,
  ) async {
    await fireStore
        .collection('chats/${getConversationID(message.toId)}/messages')
        .doc(message.sent)
        .update({'msg': updatedMessage});
  }
}
