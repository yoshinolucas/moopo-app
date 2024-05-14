import 'package:flutter/material.dart';
import 'package:app_movie/config/config.dart';

class CustomSnackBar {
  static void show(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        duration: const Duration(milliseconds: 3600),
        backgroundColor: Config.primaryColor, // Usando a cor primária do tema
      ),
    );
  }
}
