import 'dart:ui' as ui;

class Constants {
  // Using 'static double get' allows you to keep using Constants.screenWidth 
  // without parentheses, fixing all compilation errors while being responsive.
  
  static double get screenWidth {
    final view = ui.PlatformDispatcher.instance.views.first;
    return view.physicalSize.width / view.devicePixelRatio;
  }

  static double get screenHeight {
    final view = ui.PlatformDispatcher.instance.views.first;
    return view.physicalSize.height / view.devicePixelRatio;
  }

  static const double webMaxWidth = 1200.0;
}
