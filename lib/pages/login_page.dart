import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/change_password.dart';
import 'package:app_movie/pages/home.dart';
import 'package:app_movie/pages/new_user.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final username = TextEditingController();
  final pass = TextEditingController();
  bool _isLoaded = false;
  bool _isLoading = false;
  String _actualImage = Config.logo;

  verificateUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString("refresh_token") != null) {
      try {
        var response = await http.post(
            Uri.parse(
                "${Config.api}/users/refresh_token?token=${prefs.getString("refresh_token")}"),
            headers: {
              "Accept": "application/json",
              "Content-type": "application/json"
            });
        setState(() {
          _actualImage = Config.logo2;
        });
        if (response.statusCode == 200) {
          prefs.setString(
              "token", "Bearer ${json.decode(response.body)["token"]}");

          Timer(const Duration(seconds: 2), () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          });
        } else {
          setState(() {
            _isLoaded = true;
          });
          showInSnackBar('Sessão expirada, por favor faça o login novamente.');
        }
      } catch (e) {
        setState(() {
          _isLoaded = true;
        });
        showInSnackBar(
            'Erro no servidor, desculpe pelo transtorno. Por favor, volte mais tarde');
      }
    } else {
      Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _actualImage = Config.logo2;
        });
        Timer(const Duration(milliseconds: 2000), () {
          setState(() {
            _isLoaded = true;
          });
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    verificateUserSession();
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
        body: _isLoaded
            ? SingleChildScrollView(
                child: Center(
                  child: SizedBox(
                    width: 333,
                    child: Column(children: [
                      const SizedBox(height: 100),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(Config.shortLogo)),
                      const SizedBox(
                        height: 36,
                      ),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Olá!',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 22),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Que bom ter você por aqui de novo!',
                            style: TextStyle(fontSize: 16),
                          )),
                      const SizedBox(
                        height: 24,
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: TextField(
                          cursorColor: Config.primaryColor,
                          controller: username,
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
                      const SizedBox(height: 12),
                      ClipRRect(
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ChangePassword()));
                            },
                            child: Text(
                              "Esqueceu a senha?",
                              style: TextStyle(color: Config.primaryColor),
                            )),
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          login();
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStatePropertyAll(Config.primaryColor),
                          shape: const MaterialStatePropertyAll(
                              RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(32)))),
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
                                : const Text('Entrar',
                                    style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Divider(
                              color: Config.disabledColor.withOpacity(0.6),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 6.0, right: 6.0),
                            child: Text(
                              "ou",
                              style: TextStyle(
                                color: Config.disabledColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Divider(
                              color: Config.disabledColor.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      InkWell(
                        onTap: () {
                          signInGoogle();
                        },
                        child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color:
                                        Config.disabledColor.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(24)),
                            width: double.infinity,
                            height: 44,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset("lib/assets/google_sign.png"),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text('Continuar com Google'),
                              ],
                            )),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Row(
                        children: [
                          const Text(
                            "Não tem uma conta?",
                          ),
                          TextButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => NewUser()));
                              },
                              child: Text(
                                "Crie uma conta",
                                style: TextStyle(color: Config.primaryColor),
                              ))
                        ],
                      )
                    ]),
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Image.asset(_actualImage)));
  }

  login() async {
    setState(() {
      _isLoading = true;
    });
    if (username.text.isNotEmpty && pass.text.isNotEmpty) {
      try {
        await _auth.signInWithEmailAndPassword(
          email: username.text,
          password: pass.text,
        );

        var body =
            jsonEncode({'username': username.text, 'password': pass.text});
        var response = await http.post(Uri.parse("${Config.api}/users/login"),
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
        setState(() {
          _isLoading = false;
        });
        showInSnackBar(
            'Username ou Senha inválidos, Por favor tente novamente.');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      showInSnackBar('Por favor, preencha os campos obrigatórios');
    }
  }

  signInGoogle() async {
    GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleUser.authentication;

      final idToken = googleSignInAuthentication?.idToken;
      final accessToken = googleSignInAuthentication?.accessToken;

      final credential = GoogleAuthProvider.credential(
          accessToken: accessToken, idToken: idToken);

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      var body = jsonEncode({
        'username': userCredential.user!.email!,
        'password': userCredential.user!.uid
      });
      var response = await http.post(Uri.parse("${Config.api}/users/login"),
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
        Timer(Duration(seconds: 2), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => NewUser(user: userCredential.user)));
        });
      }
    }
  }
}
