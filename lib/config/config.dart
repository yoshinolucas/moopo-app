import 'package:flutter/material.dart';

class Config {
  static int id = 0;
  static int role = 1;

  static int all = -1;
  static int trigger = 0;
  static int movie = 1;
  static int serie = 2;
  static int anime = 3;

  static const urlTmdb = 'https://api.themoviedb.org';
  static const apiKey =
      'Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIwZDI0ZDYzNjgwMTNkOTJlZDJhMGI1NTEwYmU0NTU1ZSIsInN1YiI6IjY0YTQ0YmNiZTlkYTY5MDEzYjc4OTFiOCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.EymKyjzZQ1EETD0r8lLX15fSbkRofU8-Lfxr4K8pNt8';

  static const urlImage = 'https://image.tmdb.org/t/p/w185';
  static const urlImageBanner = 'https://image.tmdb.org/t/p/w500';

  String uriProd = "https://safeflix-1b60e41f7744.herokuapp.com";
  String uriTest = "http://192.168.15.6:8082";
  static const api = "http://192.168.15.6:8082";

  static const roles = {"admin": 1, "regular": 2};

  static String shortLogo = "lib/assets/moopo-shortlogo.png";
  static String shortLogoWhite = "lib/assets/moopo-shortlogo-white.png";
  static String logo = "lib/assets/moopo-logo.png";
  static String logo2 = "lib/assets/logo2.png";

  static Color? primaryColor = Color.fromARGB(255, 158, 41, 187);
  static Color? primaryColor2 = Color.fromARGB(255, 201, 136, 244);
  static Color? secondaryColor = Color.fromARGB(255, 245, 184, 31);
  static Color? inputColor = const Color.fromARGB(255, 234, 234, 234);
  static const MaterialColor primarySwatch = Colors.purple;
  static const Color btnColor = Colors.black54;
  static const Color panelColor = Color.fromARGB(255, 255, 255, 255);
  static const Color panelColor2 = Color.fromARGB(250, 250, 250, 250);
  static const Color textColor = Colors.black87;
  static const Color disabledColor = Color.fromARGB(255, 113, 113, 113);

  static const Color inputColorDark = Color.fromARGB(255, 8, 12, 18);
  static const Color panelColorDark = Color.fromARGB(255, 22, 30, 42);
  static const Color panelColor2Dark = Color.fromARGB(255, 7, 10, 14);
  static const Color textColorDark = Colors.white;
  static const Color disabledColorDark = Colors.white60;

  static const providers = {
    167: "lib/assets/claro.png",
    10: "lib/assets/prime.png",
    2: "lib/assets/apple.png",
    3: "lib/assets/google.png",
    68: "lib/assets/microsoft.png"
  };

  static const genres = [
    {
      "name": "Ação",
      "movie": 28,
      "serie": 10759,
      "icon": "lib/assets/action.png",
    },
    {
      "name": "Aventura",
      "movie": 12,
      "serie": 10759,
      "icon": "lib/assets/adventure.png"
    },
    {
      "name": "Comédia",
      "movie": 35,
      "serie": 35,
      "icon": "lib/assets/comedy.png"
    },
    {"name": "Drama", "movie": 18, "serie": 18, "icon": "lib/assets/drama.png"},
    {
      "name": "Fantasia",
      "movie": 14,
      "serie": 10765,
      "icon": "lib/assets/fantasy.png"
    },
    {
      "name": "Mistério",
      "movie": 9648,
      "serie": 9648,
      "icon": "lib/assets/mistery.png"
    },
    {
      "name": "Romance",
      "movie": 10749,
      "serie": 10766,
      "icon": "lib/assets/romance.png"
    },
    {
      "name": "Sci-Fi",
      "movie": 878,
      "serie": 10765,
      "icon": "lib/assets/scifi.png"
    }
  ];
}
