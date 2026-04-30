import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCNjkV_P_hyAIcwcRpeYDAybPVNnOUqU1s',
        appId: '1:919082993592:web:56bc536b8f8b5f0369b14d',
        messagingSenderId: '919082993592',
        projectId: 'qwicktalk',
        authDomain: 'qwicktalk.firebaseapp.com',
        storageBucket: 'qwicktalk.firebasestorage.app',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCNjkV_P_hyAIcwcRpeYDAybPVNnOUqU1s',
          appId: '1:919082993592:android:79194e72e60c897e69b14d',
          messagingSenderId: '919082993592',
          projectId: 'qwicktalk',
          storageBucket: 'qwicktalk.firebasestorage.app',
        );
      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCNjkV_P_hyAIcwcRpeYDAybPVNnOUqU1s',
          appId: '1:919082993592:ios:79194e72e60c897e69b14d',
          messagingSenderId: '919082993592',
          projectId: 'qwicktalk',
          storageBucket: 'qwicktalk.firebasestorage.app',
          iosBundleId: 'com.hemanth.qwicktalk',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}
