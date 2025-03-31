import 'dart:ui';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/widgets.dart';

class Constants {
  static FlutterView view =
      WidgetsBinding.instance.platformDispatcher.views.first;
  static Size size = view.physicalSize / view.devicePixelRatio;

  // If on the web, force physical size to 500
  static double screenWidth = kIsWeb ? 500 : size.width;
  static double screenHeight = kIsWeb ? 500 : size.height;

  // Set max width for web view
  static double webViewMaxWidth = kIsWeb ? 500 : screenWidth;
}
