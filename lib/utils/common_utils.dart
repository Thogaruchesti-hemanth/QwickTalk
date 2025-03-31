import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommonUtils {
  static void prints(Object message) {
    final pattern = RegExp('.{1,800}');
    pattern
        .allMatches('🔴🟠🟡🟢🔵' + message.toString())
        .forEach((match) => debugPrint(match.group(0)));
  }

  static String getFormattedTime({
    required BuildContext context,
    required String time,
  }) {
    final date = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    return TimeOfDay.fromDateTime(date).format(context);
  }

  static String getLastMessageTime({
    required BuildContext context,
    required String time,
    bool? showYear,
  }) {
    // Convert timestamp from milliseconds
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    print("Raw Timestamp: $time"); // Debug
    print("Converted DateTime: $sent");
    print("Show Year: $showYear");

    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year &&
        showYear == null) {
      // Message sent today → show only time
      return TimeOfDay.fromDateTime(sent).format(context);
    }

    // Show full date and time if showYear is true
    return showYear ?? false
        ? DateFormat('d MMM y, hh:mm a').format(sent)
        : DateFormat('d MMM, hh:mm a').format(sent);
  }

  static String getLastActiveTime({
    required BuildContext context,
    required String lastActive,
  }) {
    final int timeStamp = int.tryParse(lastActive) ?? -1;
    if (timeStamp == -1) return 'last seen not available';
    DateTime time = DateTime.fromMillisecondsSinceEpoch(timeStamp);
    DateTime now = DateTime.now();
    String formattedTime = TimeOfDay.fromDateTime(time).format(context);
    if (time.day == now.day &&
        time.month == now.month &&
        time.year == now.year) {
      return 'last seen today at $formattedTime';
    }

    if ((now.difference(time).inHours / 24).round() == 1) {
      return 'last seen yesterday at $formattedTime';
    }

    String formattedDate = DateFormat('d MMM').format(time);
    return 'Last seen on $formattedDate at $formattedTime';
  }

  static goToNextPage(BuildContext context, Widget nextClass) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => nextClass));
  }

  static String getMessageTime({
    required BuildContext context,
    required String time,
  }) {
    final DateTime sent = DateTime.fromMillisecondsSinceEpoch(int.parse(time));
    final DateTime now = DateTime.now();

    final formattedTime = TimeOfDay.fromDateTime(sent).format(context);
    if (now.day == sent.day &&
        now.month == sent.month &&
        now.year == sent.year) {
      return formattedTime;
    }
    final dateFormat = now.year == sent.year ? 'd MMM' : 'd MMM y';
    return '$formattedTime - ${DateFormat(dateFormat).format(sent)}';
  }
}
