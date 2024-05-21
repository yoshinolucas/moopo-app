import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/change_password.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_movie/pages/home_page.dart';
import 'package:app_movie/pages/register_page.dart';
import 'package:flutter/material.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  FirebaseFirestore db = FirebaseFirestore.instance;

  verificateUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      setState(() {
        _actualImage = Config.logo2;
      });
      if (auth.currentUser != null) {
        var db = FirebaseFirestore.instance;
        var userDb = await db
            .collection("users")
            .where("email", isEqualTo: auth.currentUser!.email)
            .get();

        prefs.setStringList("user", [
          auth.currentUser!.email.toString(),
          userDb.docs.first.get("role").toString()
        ]);

        Timer(const Duration(seconds: 2), () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        });
      } else {
        setState(() {
          _isLoaded = true;
        });
        // showInSnackBar('Sessão expirada, por favor faça o login novamente.');
      }
    } catch (e) {
      setState(() {
        _isLoaded = true;
      });
      showInSnackBar(
          'Erro no servidor, desculpe pelo transtorno. Por favor, volte mais tarde');
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
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            hintText: 'E-mail',
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
                            hintText: 'Senha',
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
                                    style: TextStyle(
                                        fontSize: 20, color: Colors.white))),
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
                                        builder: (context) => RegisterPage()));
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

  signInGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // await _googleSignIn.signInSilently();
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signInSilently();

      final GoogleSignInAuthentication googleAuth =
          await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      var userDb = await db
          .collection("users")
          .where("email", isEqualTo: googleUser.email)
          .get();
      if (userDb.docs.isNotEmpty) {
        Timer(Duration(microseconds: 300), () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        });
      } else {
        var data = {
          "email": googleUser.email,
          "firstName": googleUser.displayName
        };

        Timer(Duration(microseconds: 300), () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RegisterPage(user: data)));
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  login() async {
    setState(() {
      _isLoading = true;
    });
    if (username.text.isNotEmpty && pass.text.isNotEmpty) {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: username.text,
          password: pass.text,
        );
        User? user = userCredential.user;
        SharedPreferences prefs = await SharedPreferences.getInstance();

        var userDb = await db
            .collection("users")
            .where("email", isEqualTo: user!.email)
            .get();

        prefs.setStringList("user",
            [user.email.toString(), userDb.docs.first.get("role").toString()]);
        Timer(const Duration(seconds: 2), () {
          setState(() {
            _isLoading = false;
          });
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const HomePage()));
        });
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
}
