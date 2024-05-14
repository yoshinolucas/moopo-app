import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  darkModeHandler() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("darkMode", true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Conta"),
      ),
      body: Column(
        children: [
          TextButton(
              onPressed: () {
                setState(() {
                  darkModeHandler();
                });
              },
              child: const Text("modo escuro"))
        ],
      ),
    );
  }
}
