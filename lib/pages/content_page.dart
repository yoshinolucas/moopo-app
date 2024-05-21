import 'dart:async';
import 'dart:convert';

import 'package:app_movie/pages/trigger_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class ContentPage extends StatefulWidget {
  dynamic movie;
  int origin;
  ContentPage({Key? key, required this.movie, required this.origin})
      : super(key: key);

  @override
  State<ContentPage> createState() => _ContentPageState();
}

class _ContentPageState extends State<ContentPage> {
  bool _openText = false;
  List<String>? user;
  String? token;
  List<Trigger> triggers = [];
  bool isLoaded = false;
  bool _isLoading = false;
  List<String> triggersFavoritesString = [];
  List<int> favorites = [];
  String msgSnackbar = '';
  List<String> categories = [];
  List<dynamic>? providers = [];
  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getData();
  }

  fetchFavorites() async {
    setState(() {
      favorites = [];
    });
    var favoritesDb = await db
        .collection("favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .get();

    if (favoritesDb.docs.isNotEmpty) {
      setState(() {
        favoritesDb.docs.forEach((favorite) {
          if (favorite.get("origin") == widget.origin) {
            favorites.add(favorite["idContent"]);
          }
        });
        _isLoading = false;
      });
    }
  }

  addFavorite(content, origin) async {
    setState(() {
      _isLoading = true;
    });
    var favorite = {
      'idUser': user![Config.id],
      'idContent': content,
      'origin': origin
    };
    db.collection("favorites").add(favorite).then((value) {
      fetchFavorites();

      Timer(
          const Duration(milliseconds: 200),
          () => CustomSnackBar.show(
              context, 'Adicionado aos favoritos com sucesso.'));
    });
  }

  removeFavorite(content, origin) async {
    setState(() {
      _isLoading = true;
    });
    var querySnapshot = await db
        .collection("favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .where("idContent", isEqualTo: content)
        .where("origin", isEqualTo: origin)
        .get();
    querySnapshot.docs.forEach((doc) async {
      await doc.reference.delete();
    });

    fetchFavorites();
    Timer(
        const Duration(milliseconds: 200),
        () => CustomSnackBar.show(
            context, 'Removido dos favoritos com sucesso.'));
  }

  fetchFavoritesTriggers() async {
    var tf = await db
        .collection("triggers_favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .get();

    if (tf.docs.isNotEmpty) {
      setState(() {
        triggersFavoritesString =
            tf.docs.map((v) => v.get("idTrigger") as String).toList();
      });
    } else {
      setState(() {
        triggersFavoritesString = [];
      });
    }
    setState(() {
      _isLoading = false;
    });
    fetchTriggers();
  }

  removeFavoriteTrigger(trigger) async {
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
    fetchTriggers();
    Timer(
        const Duration(milliseconds: 200),
        () => CustomSnackBar.show(
            context, 'Removido dos favoritos com sucesso.'));
  }

  addFavoriteTrigger(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var body = {'idUser': user![Config.id], 'idTrigger': trigger};
    db.collection("triggers_favorites").add(body).then((value) {
      Timer(
          const Duration(milliseconds: 200),
          () => CustomSnackBar.show(
              context, 'Adicionado aos favoritos com sucesso.'));
      fetchTriggers();
    });
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    await fetchTriggers();
    await fetchFavorites();
    // await fetchTriggersFavorites();
    if (widget.origin == 1) {
      providers =
          await ContentRepository.fetchMoviesProvidersById(widget.movie.id);
    }
    setState(() {
      for (var genre in Config.genres) {
        if (widget.origin == 1) {
          if (widget.movie.genreIds.contains(genre['movie'])) {
            categories.add(genre['name'].toString());
          }
        } else {
          if (widget.movie.genreIds.contains(genre['serie'])) {
            categories.add(genre['name'].toString());
          }
        }
      }
      isLoaded = true;
    });
  }

  fetchTriggers() async {
    var query = await db
        .collection("triggers_content")
        .where("content", isEqualTo: widget.movie.id)
        .where("origin", isEqualTo: widget.origin)
        .where("exists", isEqualTo: true)
        .get();
    if (query.docs.isNotEmpty) {
      List<Trigger> result = [];
      await Future.forEach(query.docs, (x) async {
        var tr = db.collection("triggers").doc(x.get("trigger"));
        var query = await tr.get();
        if (query.exists) {
          var data = {
            "id": query.id,
            "name": query.get("name"),
            "description": query.get("description")
          };
          result.add(Trigger.fromJson(data));
        }
      });
      Set<Trigger> conjunto = Set<Trigger>.from(result);
      List<Trigger> arrayDistinto = conjunto.toList();

      setState(() {
        triggers = arrayDistinto;
      });
    }
  }

  renderTriggers() {
    return Padding(
      padding: MediaQuery.of(context).size.width > 520
          ? const EdgeInsets.only(left: 44.0, right: 44, bottom: 32)
          : const EdgeInsets.only(left: 6.0, right: 6, bottom: 32),
      child: GridView.builder(
        padding: const EdgeInsets.all(0),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 650
              ? 2
              : MediaQuery.of(context).size.width < 1080
                  ? 4
                  : 6,
          childAspectRatio: (1 / .4),
        ),
        itemCount: triggers.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(6.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TriggerDetails(
                            content: widget.movie.id,
                            title: widget.movie.title,
                            origin: widget.origin,
                          )));
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
                      colors: [Config.secondaryColor!, Config.primaryColor],
                    )),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        utf8.decode(latin1.encode(triggers[index].name)),
                        style: const TextStyle(color: Colors.white),
                      ),
                    )),
                _isLoading
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
                          triggersFavoritesString.contains(triggers[index].id)
                              ? removeFavoriteTrigger(triggers[index].id)
                              : addFavoriteTrigger(triggers[index].id);
                        },
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(
                            triggersFavoritesString.contains(triggers[index].id)
                                ? Icons.star
                                : Icons.star_border_outlined,
                            color: Colors.white,
                          ),
                        ))
              ]),
            ),
          ),
        ),
      ),
    );
  }

  renderProviders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Onde encontrar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(
          height: 7,
        ),
        Wrap(
          children: [
            for (dynamic provider in providers!)
              Padding(
                padding: const EdgeInsets.only(top: 9.0, right: 9, bottom: 9),
                child: Container(
                  height: 38,
                  width: provider["provider_id"] == 68 ? 130 : 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 187, 187, 187)
                              .withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(32)),
                  child: Image.asset(
                    Config.providers[provider["provider_id"]].toString(),
                    width: provider["provider_id"] == 68 ? 108 : 80,
                  ),
                ),
              )
          ],
        ),
        const SizedBox(
          height: 24,
        ),
      ],
    );
  }

  renderPageDesktop() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 100.0, left: 50, right: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(widget.movie.posterPath,
                  width: 200, fit: BoxFit.cover),
              const SizedBox(
                height: 20,
              ),
              Text(widget.movie.title,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(
                height: 6,
              ),
              Wrap(
                children: [
                  for (String name in categories)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 9.0, right: 9, bottom: 9),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 187, 187, 187)
                                    .withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(32)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 8),
                          child: Text(
                            name,
                            style: TextStyle(color: Config.primaryColor),
                          ),
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(
                height: 23,
              ),
              providers != null && providers!.isNotEmpty
                  ? renderProviders()
                  : const SizedBox(),
              const Text('Sinopse',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(
                height: 8,
              ),
              Text(
                _openText
                    ? widget.movie.overview
                    : "${widget.movie.overview.substring(0, (widget.movie.overview.length / 2).round())}...",
                style: const TextStyle(fontSize: 16),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        _openText = !_openText;
                      });
                    },
                    child: Text(
                      _openText ? 'ocultar sinopse' : 'ver mais sinopse',
                      style: TextStyle(color: Config.primaryColor),
                    )),
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gatilhos',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TriggerDetails(
                                    content: widget.movie.id,
                                    title: widget.movie.title,
                                    origin: widget.origin)));
                      },
                      child: Text(
                        "Ver mais",
                        style: TextStyle(color: Config.primaryColor),
                      ))
                ],
              ),
            ],
          ),
        ),
        renderTriggers(),
      ],
    );
  }

  renderPagePhone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.network(widget.movie.posterPath,
            width: double.infinity, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 12, right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.movie.title,
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w800)),
              const SizedBox(
                height: 3,
              ),
              Wrap(
                children: [
                  for (String name in categories)
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 9.0, right: 9, bottom: 9),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(255, 187, 187, 187)
                                    .withOpacity(0.2),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(32)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8, bottom: 8),
                          child: Text(
                            name,
                            style: TextStyle(color: Config.primaryColor),
                          ),
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(
                height: 23,
              ),
              providers != null && providers!.isNotEmpty
                  ? renderProviders()
                  : const SizedBox(),
              const Text('Sinopse',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(
                height: 8,
              ),
              Text(
                _openText
                    ? widget.movie.overview
                    : "${widget.movie.overview.substring(0, (widget.movie.overview.length / 2).round())}...",
                style: const TextStyle(fontSize: 16),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        _openText = !_openText;
                      });
                    },
                    child: Text(
                      _openText ? 'ocultar sinopse' : 'ver mais sinopse',
                      style: TextStyle(color: Config.primaryColor),
                    )),
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Gatilhos',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TriggerDetails(
                                      content: widget.movie.id,
                                      title: widget.movie.title,
                                      origin: widget.origin,
                                    )));
                      },
                      child: Text(
                        "Ver mais",
                        style: TextStyle(color: Config.primaryColor),
                      ))
                ],
              ),
            ],
          ),
        ),
        renderTriggers(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    triggers.sort((a, b) {
      bool aFavoritado = triggersFavoritesString.contains(a.id);
      bool bFavoritado = triggersFavoritesString.contains(b.id);

      if (aFavoritado && !bFavoritado) {
        return -1; // Mover "a" para cima
      } else if (!aFavoritado && bFavoritado) {
        return 1; // Mover "b" para cima
      } else {
        return 0; // Manter a ordem original
      }
    });
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0))),
        leading: InkWell(
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
            color: Colors.white,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color.fromARGB(197, 0, 0, 0),
                  Colors.transparent
                ]),
          ),
        ),
        actions: [
          InkWell(
              onTap: () {
                if (!_isLoading || isLoaded) {
                  favorites.contains(widget.movie.id)
                      ? removeFavorite(widget.movie.id, widget.origin)
                      : addFavorite(widget.movie.id, widget.origin);
                }
              },
              child: SizedBox(
                height: 60,
                width: 60,
                child: Icon(
                  favorites.contains(widget.movie.id)
                      ? Icons.star
                      : Icons.star_border_outlined,
                  color: Colors.white,
                ),
              ))
        ],
      ),
      body: isLoaded
          ? SingleChildScrollView(
              child: MediaQuery.of(context).size.width > 520
                  ? renderPageDesktop()
                  : renderPagePhone())
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
    );
  }
}
