import 'package:flutter/material.dart';
import 'package:app_movie/config/config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_movie/pages/home_page.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:app_movie/pages/register_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: 'ProximaNova',
        primarySwatch: Config.primaryColor,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          toolbarHeight: 48,
          titleTextStyle: TextStyle(fontSize: 16, color: Colors.white),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(21),
                  bottomRight: Radius.circular(21))),
          backgroundColor: Config.primaryColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
          isDense: true, // Added this
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
