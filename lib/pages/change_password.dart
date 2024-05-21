import 'dart:async';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final emailUser = TextEditingController();
  bool _isLoading = false;

  String msgSnackbar = '';
  FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  sendEmail() async {
    setState(() {
      _isLoading = true;
    });
    if (emailUser.text.isNotEmpty) {
      try {
        await _auth.sendPasswordResetEmail(email: emailUser.text);
        Timer(const Duration(seconds: 3), () {
          setState(() {
            _isLoading = false;
          });
          showInSnackBar("Email para redefinição de senha enviado com sucesso");
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginPage()));
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        showInSnackBar(
            "Nenhum usuário encontrado. Verifique novamente o e-mail digitado.");
      }
    } else {
      showInSnackBar('Por favor, Informe o seu e-mail cadastrado');
    }
  }

  void showInSnackBar(msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
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
          "Esqueceu a senha",
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
                      Icons.email,
                      size: 84,
                      color: Colors.white,
                    )),
              ),
              const Padding(
                padding:
                    EdgeInsets.only(top: 48.0, right: 48, left: 48, bottom: 32),
                child: Text(
                  "Coloque o seu endereço de e-mail para recuperar a sua senha.",
                  textAlign: TextAlign.center,
                ),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    controller: emailUser,
                    cursorColor: Config.primaryColor,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      hintText: "Email",
                    ),
                  )),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    sendEmail();
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
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white))),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
