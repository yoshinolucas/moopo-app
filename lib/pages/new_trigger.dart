import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NewTrigger extends StatefulWidget {
  const NewTrigger({super.key});

  @override
  State<NewTrigger> createState() => _NewTriggerState();
}

class _NewTriggerState extends State<NewTrigger> {
  final name = TextEditingController();
  final description = TextEditingController();
  List<Trigger> triggers = [];

  @override
  void initState() {
    super.initState();
  }

  postTrigger() async {
    var body =
        json.encode({"name": name.text, "description": description.text});
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await http
        .post(Uri.parse("${Config.api}/triggers/add"), body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json",
      "Authorization": prefs.get("token").toString()
    });
    if (response.statusCode == 200) {
      Timer(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Gatilho")),
      body: Column(children: [
        TextField(
          controller: name,
        ),
        TextField(
          controller: description,
        ),
        ElevatedButton(
            onPressed: () {
              postTrigger();
            },
            child: const Text("Salvar"))
      ]),
    );
  }
}
