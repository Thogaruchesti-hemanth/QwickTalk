import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: dotenv.env['API_KEY_WEB']!,
        appId: dotenv.env['APP_ID_WEB']!,
        messagingSenderId: dotenv.env['SENDER_ID']!,
        projectId: dotenv.env['PROJECT_ID']!,
        authDomain: dotenv.env['AUTH_DOMAIN'],
        storageBucket: dotenv.env['STORAGE_BUCKET'],
        measurementId: dotenv.env['MEASUREMENT_ID'],
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: dotenv.env['API_KEY_ANDROID']!,
          appId: dotenv.env['APP_ID_ANDROID']!,
          messagingSenderId: dotenv.env['SENDER_ID']!,
          projectId: dotenv.env['PROJECT_ID']!,
          storageBucket: dotenv.env['STORAGE_BUCKET'],
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return FirebaseOptions(
          apiKey: dotenv.env['API_KEY_IOS']!,
          appId: dotenv.env['APP_ID_IOS']!,
          messagingSenderId: dotenv.env['SENDER_ID']!,
          projectId: dotenv.env['PROJECT_ID']!,
          storageBucket: dotenv.env['STORAGE_BUCKET'],
          iosBundleId: dotenv.env['IOS_BUNDLE_ID'],
          iosClientId: dotenv.env['IOS_CLIENT_ID'],
        );
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }
}
