import 'package:flutter/material.dart';

class ToastUtil {
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.green);
  }

  static void error(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.red);
  }

  static void info(BuildContext context, String message) {
    show(context, message, backgroundColor: Colors.blue);
  }
}
