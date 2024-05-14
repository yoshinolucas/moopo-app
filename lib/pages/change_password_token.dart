import 'dart:async';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/change_password_final.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChangePasswordToken extends StatefulWidget {
  const ChangePasswordToken({super.key});

  @override
  State<ChangePasswordToken> createState() => _ChangePasswordTokenState();
}

class _ChangePasswordTokenState extends State<ChangePasswordToken> {
  final token = TextEditingController();
  bool _isLoading = false;
  String msgSnackbar = '';

  @override
  void initState() {
    super.initState();
    setState(() {
      msgSnackbar = 'Por favor, verifique seu e-mail.';
    });
    showInSnackBar();
  }

  validateToken() async {
    setState(() {
      _isLoading = true;
    });
    var response = await http.post(Uri.parse(
        "${Config.api}/users/validate_token_change_pass?token=${token.text}"));
    if (response.statusCode == 200) {
      Timer(const Duration(seconds: 3), () {
        setState(() {
          _isLoading = false;
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChangePasswordFinal(token: token.text)));
      });
    } else {
      setState(() {
        msgSnackbar = "Código inválido, por favor verifique novamente.";
        _isLoading = false;
      });
      showInSnackBar();
    }
  }

  void showInSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msgSnackbar, style: TextStyle(color: Colors.white)),
        duration: const Duration(milliseconds: 3600),
        backgroundColor: Config.primaryColor,
      ),
    );
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
        iconTheme: const IconThemeData(color: Config.textColor),
        shadowColor: Colors.transparent,
        backgroundColor: Config.panelColor,
        title: const Text(
          "Verifique o seu e-mail",
          style: TextStyle(color: Config.textColor),
        ),
      ),
      body: Center(
        child: SizedBox(
          width: 330,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 69,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(64),
                child: Container(
                    color: Config.primaryColor2,
                    height: 120,
                    width: 120,
                    child: const Icon(
                      Icons.lock,
                      size: 84,
                      color: Colors.white,
                    )),
              ),
              const Padding(
                padding:
                    EdgeInsets.only(top: 48.0, right: 48, left: 48, bottom: 32),
                child: Text(
                  "Coloque os 6 dígitos do código enviado para o e-mail.",
                  textAlign: TextAlign.center,
                ),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    controller: token,
                    cursorColor: Config.primaryColor,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      isDense: true,
                      hintText: "Código",
                    ),
                  )),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    validateToken();
                  },
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Config.btnColor),
                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32)))),
                  ),
                  child: Container(
                      alignment: Alignment.center,
                      height: 38,
                      padding: const EdgeInsets.all(6),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('Continuar',
                              style: TextStyle(fontSize: 16))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
