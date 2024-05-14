import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/perfil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class EditUser extends StatefulWidget {
  const EditUser({super.key});

  @override
  State<EditUser> createState() => _EditUserState();
}

class _EditUserState extends State<EditUser> {
  final username = TextEditingController();
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final telefone = TextEditingController();
  bool _isLoading = false;
  bool _isLoaded = false;
  List<String>? user;
  String? token;
  String msgSnackbar = '';
  String? image;
  bool _isLoadingImage = false;

  @override
  void initState() {
    super.initState();
    fetchUser();
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

  fetchUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });

    var response = await http.get(
        Uri.parse("${Config.api}/users/details?id=${user![Config.id]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      var responseJson = json.decode(response.body);
      setState(() {
        username.text = responseJson['username'];
        firstName.text = responseJson['firstName'];
        lastName.text = responseJson['lastName'] ?? '';
        email.text = responseJson['email'];
        image = responseJson['image'];
        _isLoaded = true;
      });
    }
  }

  updateUser() async {
    setState(() {
      _isLoading = true;
    });
    if (username.text.isNotEmpty &&
        email.text.isNotEmpty &&
        firstName.text.isNotEmpty) {
      var body = json.encode({
        "username": username.text,
        "email": email.text,
        "firstName": firstName.text,
        "lastName": lastName.text,
        "image": image
      });
      var response = await http.put(
          Uri.parse("${Config.api}/users/update?id=${user![Config.id]}"),
          body: body,
          headers: {
            "Accept": "application/json",
            "content-type": "application/json",
            "Authorization": token!
          });
      if (response.statusCode == 200) {
        Timer(const Duration(seconds: 2), () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const PerfilPage()));
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        showInSnackBar('Erro ao atualizar. Tente novamente mais tarde.');
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      showInSnackBar('Preencha os campos obrigatórios.');
    }
  }

  uploadFile() async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(withData: true);

      setState(() {
        _isLoadingImage = true;
      });
      var now = DateTime.now().millisecondsSinceEpoch;
      final file = pickedFile!.files.first;

      final reference = FirebaseStorage.instance
          .ref()
          .child("perfil-photo/${user![Config.id]}-$now");

      await reference.putData(
          file.bytes!, SettableMetadata(contentType: 'image/png'));

      var imgUrl = await reference.getDownloadURL();
      setState(() {
        image = imgUrl;
        _isLoadingImage = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingImage = false;
      });
      showInSnackBar('Erro no servidor, tente novamente mais tarde.');
    }
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
          title: const Text("Perfil"),
        ),
        body: _isLoaded
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () {
                          uploadFile();
                        },
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(84),
                              child: Container(
                                  alignment: Alignment.center,
                                  color: Config.panelColor2,
                                  height: 100,
                                  width: 100,
                                  child: _isLoadingImage || !_isLoaded
                                      ? SizedBox(
                                          height: 32,
                                          width: 32,
                                          child: CircularProgressIndicator(
                                              color: Config.primaryColor),
                                        )
                                      : image == null
                                          ? const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    size: 16,
                                                  ),
                                                  Text(
                                                    "Mudar foto",
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  )
                                                ])
                                          : Image.network(image!)),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(64),
                              child: Container(
                                color: Colors.grey[350],
                                height: 24,
                                width: 24,
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Nome"),
                              const SizedBox(
                                height: 4,
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  cursorColor: Config.primaryColor,
                                  controller: firstName,
                                  style:
                                      const TextStyle(color: Config.textColor),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true, // Added this
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Sobrenome"),
                              const SizedBox(
                                height: 4,
                              ),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: TextField(
                                  style:
                                      const TextStyle(color: Config.textColor),
                                  controller: lastName,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true, // Added this
                                    contentPadding: EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text("Nome de usuário"),
                    const SizedBox(
                      height: 4,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        style: const TextStyle(color: Config.textColor),
                        cursorColor: Config.primaryColor,
                        controller: username,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Email"),
                    const SizedBox(
                      height: 4,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: TextField(
                        style: const TextStyle(color: Config.textColor),
                        cursorColor: Config.primaryColor,
                        autocorrect: false,
                        controller: email,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true, // Added this
                          contentPadding: EdgeInsets.all(15),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                style: const ButtonStyle(
                                    shadowColor: MaterialStatePropertyAll(
                                        Colors.transparent),
                                    shape: MaterialStatePropertyAll(
                                        RoundedRectangleBorder(
                                            side: BorderSide(
                                                color: Config.textColor),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(24)))),
                                    backgroundColor: MaterialStatePropertyAll(
                                        Colors.transparent)),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                    alignment: Alignment.center,
                                    height: 44,
                                    padding: const EdgeInsets.all(10),
                                    child: const Text('Cancelar',
                                        style: TextStyle(
                                            fontSize: 18,
                                            color: Config.textColor)))),
                          ),
                        ),
                        const SizedBox(
                          width: 16,
                        ),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                  shape: const MaterialStatePropertyAll(
                                      RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(32)))),
                                  backgroundColor: MaterialStatePropertyAll(
                                      Config.primaryColor)),
                              onPressed: () {
                                updateUser();
                              },
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
                                      : const Text('Salvar',
                                          style: TextStyle(fontSize: 18))),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: SizedBox(
                  height: 32,
                  width: 32,
                  child: CircularProgressIndicator(color: Config.primaryColor),
                ),
              ),
        bottomNavigationBar: const Footer(
          current: 5,
        ));
  }
}
