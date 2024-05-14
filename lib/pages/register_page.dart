import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_movie/pages/home_page.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  final User? user;
  const RegisterPage({super.key, this.user});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final pass = TextEditingController();
  bool signInThird = false;
  bool _isLoading = false;
  String msgSnackbar = '';

  @override
  void initState() {
    super.initState();
  }

  postUser() async {
    setState(() {
      _isLoading = true;
    });
    if (username.text.isNotEmpty &&
        (email.text.isNotEmpty) &&
        (pass.text.isNotEmpty) &&
        (firstName.text.isNotEmpty)) {
      Map<String, dynamic> user = {
        "username": username.text,
        "email": email.text,
        "password": pass.text,
        "firstName": firstName.text,
        "lastName": lastName.text,
        "role": 2,
        "active": true,
        "image": ""
      };

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text,
          password: pass.text,
        );
        User? userAuth = userCredential.user;

        var db = FirebaseFirestore.instance;
        SharedPreferences prefs = await SharedPreferences.getInstance();

        var userDb = await db
            .collection("users")
            .where("email", isEqualTo: userAuth!.email)
            .get();

        prefs.setStringList("user", [
          userAuth.email.toString(),
          userDb.docs.first.get("role").toString()
        ]);
        db.collection("users").add(user).then((value) => {
              Timer(const Duration(seconds: 2), () {
                setState(() {
                  _isLoading = false;
                });
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              })
            });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        Timer(const Duration(milliseconds: 200), () {
          CustomSnackBar.show(context, "Senha deve ter ao menos 6 caractéres");
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Center(
          child: SizedBox(
        width: 333,
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 100),
          Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(Config.shortLogo)),
          const SizedBox(
            height: 10,
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Olá!',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 26),
            ),
          ),
          const SizedBox(
            height: 19,
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child:
                Text('Para efeturar o cadastro, preencha os campos a seguir:'),
          ),
          const SizedBox(
            height: 19,
          ),
          signInThird
              ? const SizedBox()
              : TextField(
                  cursorColor: Config.primaryColor,
                  controller: firstName,
                  style: const TextStyle(color: Config.textColor),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    hintText: 'Nome Completo',
                  ),
                ),
          SizedBox(height: signInThird ? 0 : 12),
          TextField(
            cursorColor: Config.primaryColor,
            controller: username,
            style: const TextStyle(color: Config.textColor),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person),
              hintText: 'Nome de usuário',
            ),
          ),
          const SizedBox(height: 12),
          signInThird
              ? const SizedBox()
              : TextField(
                  cursorColor: Config.primaryColor,
                  controller: email,
                  style: const TextStyle(color: Config.textColor),
                  decoration: const InputDecoration(
                    fillColor: Colors.blue,
                    prefixIcon: Icon(Icons.email),
                    hintText: 'E-mail',
                  ),
                ),
          SizedBox(height: signInThird ? 0 : 12),
          signInThird
              ? const SizedBox()
              : TextField(
                  cursorColor: Config.primaryColor,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.visiblePassword,
                  controller: pass,
                  // style: const TextStyle(color: Config.textColor),
                  decoration: const InputDecoration(
                    fillColor: Colors.blue,
                    prefixIcon: Icon(Icons.lock),
                    hintText: 'Senha',
                  ),
                ),
          const SizedBox(
            height: 24,
          ),
          ElevatedButton(
            onPressed: () {
              postUser();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStatePropertyAll(Config.primaryColor),
              shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(32)))),
            ),
            child: Container(
                alignment: Alignment.center,
                height: 44,
                padding: const EdgeInsets.all(10),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const Text('Cadastrar',
                        style: TextStyle(fontSize: 20, color: Colors.white))),
          ),
          const SizedBox(
            height: 32,
          ),
          Row(
            children: [
              const Text("Já tem uma conta?"),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Faça login",
                    style: TextStyle(color: Config.primaryColor),
                  ))
            ],
          )
        ]),
      )),
    ));
  }
}
