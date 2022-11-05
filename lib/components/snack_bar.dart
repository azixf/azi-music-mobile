import 'dart:developer';
import 'package:flutter/material.dart';

class ShowSnackBar {
  void showSnackBar(
    BuildContext context,
    String title,
    {
      SnackBarAction? action,
      Duration duration = const Duration(seconds: 2),
      bool noAction = false
    }
  ){
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: duration,
          elevation: 6,
          backgroundColor: Colors.grey[900],
          behavior: SnackBarBehavior.floating,
          content: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          action: noAction ?  null : action ?? SnackBarAction(
            textColor: Theme.of(context).colorScheme.secondary,
              label: '确定', 
              onPressed: () {}
            ),
        ),
      );
    } catch(e) {
      log('Failed to show SnackBar with title: $title');
    }
  }
}