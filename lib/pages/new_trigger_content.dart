import 'dart:async';
import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NewTriggerContent extends StatefulWidget {
  final int content;
  final int origin;
  const NewTriggerContent(
      {super.key, required this.content, required this.origin});

  @override
  State<NewTriggerContent> createState() => _NewTriggerContentState();
}

class _NewTriggerContentState extends State<NewTriggerContent> {
  List<Trigger> triggers = [];
  List<int> currents = [];
  List<Trigger> _selectedsTriggers = [];
  List<String>? user;
  String? token;
  @override
  void initState() {
    super.initState();
    fetchTriggers();
  }

  fetchTriggers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
      triggers = [];
      currents = [];
      _selectedsTriggers = [];
    });
    var responseCurrent = await http.get(
        Uri.parse(
            "${Config.api}/triggers/content?id=${widget.content}&user=${user![Config.id]}&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (responseCurrent.statusCode == 200) {
      var response = await http.post(
          Uri.parse("${Config.api}/triggers/all?page=1&limit=40"),
          body: json.encode({"search": "", "order": "id"}),
          headers: {
            "Accept": "application/json",
            "content-type": "application/json",
            "Authorization": token!
          });
      if (response.statusCode == 200) {
        var all = json.decode(response.body);
        var currentsRaw = json.decode(responseCurrent.body);
        for (var current in currentsRaw) {
          setState(() {
            currents.add(current["trigger"]["id"]);
            Trigger obj = Trigger.fromJson(current["trigger"]);
            _selectedsTriggers.add(obj);
          });
        }
        for (var item in all) {
          if (!currents.contains(item["id"])) {
            Trigger opt = Trigger.fromJson(item);
            setState(() {
              triggers.add(opt);
            });
          }
        }
      }
    }
  }

  addTrigger() async {
    for (var trigger in _selectedsTriggers) {
      if (!currents.contains(trigger.id)) {
        var response = await http.post(
            Uri.parse(
                "${Config.api}/triggers/vote?id=${trigger.id}&content=${widget.content}&vote=0&user=0&origin=${widget.origin}"),
            headers: {
              "Accept": "application/json",
              "content-type": "application/json",
              "Authorization": token!
            });
        if (response.statusCode == 200) {
          Timer(const Duration(seconds: 2), () {
            Navigator.pop(context);
          });
        }
      }
    }
  }

  removeTrigger(trigger) async {
    var response = await http.delete(
        Uri.parse(
            "${Config.api}/triggers/remove_trigger_content?id=$trigger&content=${widget.content}&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchTriggers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(children: [
        DropdownButton<Trigger>(
          items: triggers.map((value) {
            return DropdownMenuItem(
                value: value,
                child: Text(utf8.decode(latin1.encode(value.name))));
          }).toList(),
          onChanged: (selected) {
            if (selected != null) {
              setState(() {
                _selectedsTriggers.add(selected);
                triggers.remove(selected);
              });
            }
          },
        ),
        Expanded(
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: _selectedsTriggers.length,
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Text(utf8
                        .decode(latin1.encode(_selectedsTriggers[index].name))),
                    IconButton(
                        onPressed: () {
                          removeTrigger(_selectedsTriggers[index].id);
                        },
                        icon: const Icon(Icons.close))
                  ],
                );
              }),
        ),
        ElevatedButton(
            onPressed: () {
              addTrigger();
            },
            child: const Text("Salvar"))
      ]),
    );
  }
}
