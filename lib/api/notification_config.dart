import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationConfig {
  static String get projectId => dotenv.get('FCM_PROJECT_ID', fallback: 'qwicktalk');
  static String get clientEmail => dotenv.get('FCM_CLIENT_EMAIL', fallback: '');
  static String get clientId => dotenv.get('FCM_CLIENT_ID', fallback: '');
  static String get privateKey => dotenv.get('FCM_PRIVATE_KEY', fallback: '').replaceAll('"', '');
}
