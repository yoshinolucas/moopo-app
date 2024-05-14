import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(
      theme: ThemeData(
          fontFamily: 'ProximaNova',
          inputDecorationTheme: InputDecorationTheme(
              hintStyle: const TextStyle(color: Config.disabledColor),
              filled: true,
              fillColor: Config.inputColor),
          iconTheme: const IconThemeData(color: Config.textColor),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              color: Config.textColor,
            ),
          ),
          primarySwatch: Config.primarySwatch,
          appBarTheme: AppBarTheme(
            toolbarHeight: 48,
            titleTextStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'ProximaNova'),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(21),
                    bottomRight: Radius.circular(21))),
            backgroundColor: Config.primaryColor,
          ),
          scaffoldBackgroundColor: Config.panelColor),
      home: const LoginPage()));
}
