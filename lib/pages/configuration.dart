import 'dart:async';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/help.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:app_movie/pages/perfil.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key});

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        automaticallyImplyLeading: false,
        title: const Text(
          "Configurações",
        ),
      ),
      body: Stack(children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Config.textColor,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PerfilPage()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Perfil",
                        )
                      ],
                    ),
                  )),
              // Divider(
              //   color: Colors.grey[350],
              // ),
              // TextButton(
              //     style: TextButton.styleFrom(
              //       foregroundColor: Config.textColor,
              //     ),
              //     onPressed: () {
              //       Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //               builder: (context) => const PreferencesPage()));
              //     },
              //     child: const Padding(
              //       padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
              //       child: Row(
              //         children: [
              //           Icon(
              //             Icons.settings,
              //           ),
              //           SizedBox(width: 8),
              //           Text(
              //             "Configurações da conta",
              //           )
              //         ],
              //       ),
              //     )),
              Divider(
                color: Colors.grey[350],
              ),
              TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Config.textColor,
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HelpPage()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Ajuda",
                        )
                      ],
                    ),
                  )),
              Divider(
                color: Colors.grey[350],
              ),
              TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Config.textColor,
                  ),
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    prefs.remove("user");
                    prefs.remove("token");
                    prefs.remove("refresh_token");
                    setState(() {
                      _isLoading = true;
                    });
                    Timer(const Duration(seconds: 1), () {
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (Route<dynamic> route) => false);
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 8.0, left: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Sair",
                        )
                      ],
                    ),
                  )),
            ],
          ),
        ),
        _isLoading
            ? Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(color: Config.primaryColor),
                ),
              )
            : const SizedBox(),
      ]),
      bottomNavigationBar: const Footer(current: 5),
    );
  }
}
