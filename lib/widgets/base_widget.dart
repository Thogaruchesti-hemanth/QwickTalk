import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';

import '../utils/constants.dart';

class BaseWidget extends StatelessWidget {
  final Widget child;
  const BaseWidget({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        bool isMobile =
            sizingInformation.deviceScreenType == DeviceScreenType.mobile;
        return Center(
          child:
              isMobile
                  ? child
                  : SizedBox(width: Constants.webViewMaxWidth, child: child),
        );
      },
    );
  }
}
