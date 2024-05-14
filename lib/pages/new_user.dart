import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NewUser extends StatefulWidget {
  final User? user;
  NewUser({super.key, this.user});

  @override
  State<NewUser> createState() => _NewUserState();
}

class _NewUserState extends State<NewUser> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final firstName = TextEditingController();
  final email = TextEditingController();
  final username = TextEditingController();
  final pass = TextEditingController();
  bool signInThird = false;
  bool _isLoading = false;
  String msgSnackbar = '';

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      setState(() {
        signInThird = true;
      });
    }
  }

  postUser() async {
    setState(() {
      _isLoading = true;
    });

    if (username.text.isNotEmpty &&
            (email.text.isNotEmpty) &&
            (pass.text.isNotEmpty) &&
            (firstName.text.isNotEmpty) ||
        signInThird && username.text.isNotEmpty) {
      if (pass.text.length > 8 || signInThird) {
        var body = json.encode({
          "username": username.text,
          "email": signInThird ? widget.user!.email : email.text,
          "password": signInThird ? widget.user!.uid : pass.text,
          "firstName": signInThird ? widget.user!.displayName : firstName.text,
          "role": 2,
          "active": true
        });
        var response = await http
            .post(Uri.parse("${Config.api}/users/add"), body: body, headers: {
          "Accept": "application/json",
          "content-type": "application/json",
        });
        if (response.statusCode == 200) {
          try {
            if (!signInThird) {
              await _auth.createUserWithEmailAndPassword(
                email: email.text,
                password: signInThird ? widget.user!.uid : pass.text,
              );
            }
            showInSnackBar('Bem vindo! Você foi registrado com sucesso');

            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.remove("refresh_token");
            prefs.remove("token");
            prefs.remove("user");

            var body = jsonEncode({
              'username': username.text,
              'password': signInThird ? widget.user!.uid : pass.text
            });
            response = await http.post(Uri.parse("${Config.api}/users/login"),
                body: body,
                headers: {
                  "Accept": "application/json",
                  "Content-type": "application/json"
                });

            if (response.statusCode == 200) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString(
                  "token", "Bearer ${json.decode(response.body)["token"]}");

              prefs.setString("refresh_token",
                  "Bearer ${json.decode(response.body)["refresh_token"]}");

              prefs.setStringList("user", [
                json.decode(response.body)["id"].toString(),
                json.decode(response.body)["role"].toString()
              ]);

              Timer(const Duration(seconds: 2), () {
                setState(() {
                  _isLoading = false;
                });
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const HomePage()));
              });
            } else {
              setState(() {
                _isLoading = false;
              });
              showInSnackBar(
                  'Username ou Senha inválidos, Por favor tente novamente.');
            }
          } catch (e) {
            throw Exception('Failed to Insert User Firebase');
          }
        } else {
          throw Exception('Failed to Insert User');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showInSnackBar('Sua senha deve ter mais que 8 caractéres.');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      showInSnackBar('Preencha os campos obrigatórios.');
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
              : ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    cursorColor: Config.primaryColor,
                    controller: firstName,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      border: InputBorder.none,
                      hintText: 'Nome Completo',
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(15),
                    ),
                  ),
                ),
          SizedBox(height: signInThird ? 0 : 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: TextField(
              cursorColor: Config.primaryColor,
              controller: username,
              style: const TextStyle(color: Config.textColor),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person),
                border: InputBorder.none,
                hintText: 'Nome de usuário',
                isDense: true, // Added this
                contentPadding: EdgeInsets.all(15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          signInThird
              ? const SizedBox()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    cursorColor: Config.primaryColor,
                    controller: email,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      border: InputBorder.none,
                      hintText: 'E-mail',
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(15),
                    ),
                  ),
                ),
          SizedBox(height: signInThird ? 0 : 12),
          signInThird
              ? const SizedBox()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    cursorColor: Config.primaryColor,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    keyboardType: TextInputType.visiblePassword,
                    controller: pass,
                    style: const TextStyle(color: Config.textColor),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      border: InputBorder.none,
                      hintText: 'Senha',
                      isDense: true, // Added this
                      contentPadding: EdgeInsets.all(15),
                    ),
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
              shape: const MaterialStatePropertyAll(RoundedRectangleBorder(
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
                    : const Text('Cadastrar', style: TextStyle(fontSize: 20))),
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
