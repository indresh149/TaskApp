import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccessSnackbar(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.green);
  }

  static void showErrorSnackbar(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.red);
  }

  static void showInfoSnackbar(BuildContext context, String message) {
    _showSnackbar(context, message, Theme.of(context).colorScheme.secondary);
  }

  static void _showSnackbar(BuildContext context, String message, Color backgroundColor) {
    if (ScaffoldMessenger.maybeOf(context) != null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}