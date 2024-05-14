import 'dart:convert';

import 'package:app_movie/pages/search.dart';
import 'package:app_movie/pages/trigger_content_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/new_trigger.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Triggers extends StatefulWidget {
  final List<Trigger>? triggers;
  const Triggers({super.key, this.triggers});

  @override
  State<Triggers> createState() => _TriggersState();
}

class _TriggersState extends State<Triggers> {
  String _index = "-1";
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool _isLoaded = false;
  List<Trigger>? triggers = [];
  List<Trigger> triggersFavorites = [];
  List<String> favorites = [];
  bool _isLoading = false;
  List<String>? user;
  String? token;

  int currentPage = 1;
  ScrollController _scrollController = ScrollController();
  DocumentSnapshot? lastDocument;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // The user has reached the end of the list, load more items.
        fetchTriggers(true);
      }
    });
    getData();
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
    });
    fetchFavorites(true);
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

  fetchFavorites(isPagination) async {
    var db = FirebaseFirestore.instance;
    var tf = await db
        .collection("triggers_favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .get();

    if (tf.docs.isNotEmpty) {
      setState(() {
        favorites = tf.docs.map((v) => v.get("idTrigger") as String).toList();
      });
    } else {
      setState(() {
        favorites = [];
      });
    }
    setState(() {
      _isLoading = false;
    });
    fetchTriggers(isPagination);
  }

  fetchTriggers(isPagination) async {
    if (widget.triggers!.isNotEmpty) {
      setState(() {
        triggers = widget.triggers;
        triggersFavorites =
            triggers!.where((t) => favorites.contains(t.id)).toList();
        _isLoaded = true;
      });
    } else {
      Query<Map<String, dynamic>> query = db.collection("triggers");
      if (lastDocument != null && isPagination) {
        query = query.startAfterDocument(lastDocument!);
      }
      var querySnapshot = await query.get();
      if (querySnapshot.docs.isNotEmpty) {
        List<Trigger> result = querySnapshot.docs.map((x) {
          var data = {
            "id": x.id,
            "name": x.get("name"),
            "description": x.get("description")
          };
          return Trigger.fromJson(data);
        }).toList();

        setState(() {
          if (isPagination) {
            lastDocument = querySnapshot.docs.last;
            triggers = [...triggers!, ...result];
          }

          triggersFavorites =
              triggers!.where((t) => favorites.contains(t.id)).toList();
        });
      }
      setState(() {
        _isLoaded = true;
      });
    }
  }

  loadMore() async {}

  removeFavorite(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var querySnapshot = await db
        .collection("triggers_favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .where("idTrigger", isEqualTo: trigger)
        .get();
    querySnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });

    fetchFavorites(false);
    showInSnackBar('Removido dos favoritos com sucesso.');
  }

  addFavorite(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var body = {'idUser': user![Config.id], 'idTrigger': trigger};
    db.collection("triggers_favorites").add(body).then((value) {
      fetchFavorites(false);
      showInSnackBar('Adicionado aos favoritos com sucesso.');
    });
  }

  renderTriggers() {
    return ListView(
      controller: _scrollController,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 12),
          child: Text(
            "Meus gatilhos",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        triggersFavorites.isEmpty
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text("Nenhum gatilho favoritado"),
                  ),
                  SizedBox(
                    height: 24,
                  ),
                ],
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 650
                      ? 2
                      : MediaQuery.of(context).size.width < 1080
                          ? 4
                          : 6,
                  childAspectRatio: (1 / .4),
                ),
                itemCount: triggersFavorites.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TriggerContentList(
                                  trigger: triggersFavorites[index].id,
                                  name: triggersFavorites[index].name)));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(alignment: Alignment.topRight, children: [
                        Container(
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Config.secondaryColor!,
                                Config.primaryColor!
                              ],
                            )),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Text(
                                utf8.decode(latin1
                                    .encode(triggersFavorites[index].name)),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600),
                              ),
                            )),
                        _isLoading && _index == triggersFavorites[index].id
                            ? const SizedBox(
                                height: 30,
                                width: 30,
                                child: Padding(
                                  padding: EdgeInsets.all(6.0),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ))
                            : InkWell(
                                onTap: () {
                                  setState(() {
                                    _index = triggersFavorites[index].id;
                                  });
                                  removeFavorite(triggersFavorites[index].id);
                                },
                                child: const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.white,
                                  ),
                                ))
                      ]),
                    ),
                  ),
                ),
              ),
        const Padding(
          padding: EdgeInsets.only(left: 8.0, top: 16.0),
          child: Text(
            "Gatilhos",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        triggers!.isEmpty
            ? const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text("Nenhum gatilho encontrado"),
                  ),
                  SizedBox(
                    height: 24,
                  ),
                ],
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 650
                      ? 2
                      : MediaQuery.of(context).size.width < 1080
                          ? 4
                          : 6,
                  childAspectRatio: (1 / .4),
                ),
                itemCount: triggers!.length, // Add 1 for the loading indicator.
                itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TriggerContentList(
                                      trigger: triggers![index].id,
                                      name: triggers![index].name)));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              Stack(alignment: Alignment.topRight, children: [
                            Container(
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Config.secondaryColor!,
                                    Config.primaryColor!
                                  ],
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Text(
                                    utf8.decode(
                                        latin1.encode(triggers![index].name)),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                )),
                            _isLoading && _index == triggers![index].id
                                ? const SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ))
                                : InkWell(
                                    onTap: () {
                                      setState(() {
                                        _index = triggers![index].id;
                                      });
                                      favorites.contains(triggers![index].id)
                                          ? removeFavorite(triggers![index].id)
                                          : addFavorite(triggers![index].id);
                                    },
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: Icon(
                                        favorites.contains(triggers![index].id)
                                            ? Icons.star
                                            : Icons.star_border_outlined,
                                        color: Colors.white,
                                      ),
                                    ))
                          ]),
                        ),
                      ),
                    )),
        _isLoading
            ? Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  ),
                ),
              )
            : const SizedBox()
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Gatilhos"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (contexxt) => const SearchPage()));
              },
              icon: const Icon(Icons.search)),
          user![Config.role] == '1'
              ? IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NewTrigger()));
                  },
                  icon: const Icon(Icons.add))
              : const SizedBox()
        ],
      ),
      body: _isLoaded
          ? renderTriggers()
          : Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Config.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
      bottomNavigationBar: const Footer(current: 2),
    );
  }
}
