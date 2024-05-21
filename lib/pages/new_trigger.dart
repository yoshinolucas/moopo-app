import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:flutter/material.dart';

class NewTrigger extends StatefulWidget {
  const NewTrigger({super.key});

  @override
  State<NewTrigger> createState() => _NewTriggerState();
}

class _NewTriggerState extends State<NewTrigger> {
  final name = TextEditingController();
  final description = TextEditingController();
  List<Trigger> triggers = [];
  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  postTrigger() async {
    var body = {"name": name.text, "description": description.text};
    db
        .collection("triggers")
        .add(body)
        .then((value) => Timer(const Duration(seconds: 2), () {
              Navigator.pop(context);
            }));
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
