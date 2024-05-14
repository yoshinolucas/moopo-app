import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChangePasswordFinal extends StatefulWidget {
  final String token;
  const ChangePasswordFinal({super.key, required this.token});

  @override
  State<ChangePasswordFinal> createState() => _ChangePasswordFinalState();
}

class _ChangePasswordFinalState extends State<ChangePasswordFinal> {
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool _isLoading = false;
  String msgSnackbar = '';

  changePassword() async {
    setState(() {
      _isLoading = true;
    });
    if (password.text.isNotEmpty &&
        confirmPassword.text.isNotEmpty &&
        password.text == confirmPassword.text) {
      var body = json.encode({"password": password.text});
      var response = await http.put(
          Uri.parse(
              "${Config.api}/users/change_password?token=${widget.token}"),
          body: body,
          headers: {
            "Accept": "application/json",
            "content-type": "application/json"
          });
      if (response.statusCode == 200) {
        setState(() {
          msgSnackbar = 'Sua senha foi alterado com sucesso!';
        });
        showInSnackBar();

        Timer(const Duration(seconds: 3), () {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false);
        });
      } else {
        setState(() {
          msgSnackbar =
              "Erro no servidor. Desculpe pelo transtorno, tente novamente mais tarde.";
          _isLoading = false;
        });
        showInSnackBar();
      }
    } else {
      setState(() {
        msgSnackbar = "Senhas distintas, verifique novamente.";
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
          "Recupere a sua senha",
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
                      Icons.password,
                      size: 84,
                      color: Colors.white,
                    )),
              ),
              const Padding(
                padding:
                    EdgeInsets.only(top: 48.0, right: 48, left: 48, bottom: 32),
                child: Text(
                  "Coloque a sua nova senha para conseguir fazer o seu login.",
                  textAlign: TextAlign.center,
                ),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    controller: password,
                    style: const TextStyle(color: Config.textColor),
                    cursorColor: Config.primaryColor,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      isDense: true,
                      hintText: "Nova senha",
                    ),
                  )),
              const SizedBox(
                height: 12,
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    controller: confirmPassword,
                    cursorColor: Config.primaryColor,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      isDense: true,
                      hintText: "Confirme a nova senha",
                    ),
                  )),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    changePassword();
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
                          : const Text('Enviar',
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
