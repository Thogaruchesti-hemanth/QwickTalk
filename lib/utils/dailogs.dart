import 'package:flutter/material.dart';

class Dialogs {
  /// Show a floating Snackbar message
  static void showSnackBar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.blue.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a progress indicator dialog
  static void showProgressBar(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  /// Show a simple alert dialog with an "OK" button
  static void showAlertDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  /// Show a confirmation dialog with "Yes" and "No" buttons
  static Future<bool?> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(message),
            actions: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.cancel, color: Colors.white),
                label: const Text("No", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text("Yes", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  /// Show an input dialog where users can enter text
  static Future<String?> showInputDialog(
    BuildContext context,
    String title,
    String hint,
  ) async {
    String inputText = '';
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: TextField(
              onChanged: (value) => inputText = value,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, inputText),
                child: const Text("OK", style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }
}
