import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/trigger_details.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  List<int> triggerFavorites = [];
  List<int> favorites = [];
  String msgSnackbar = '';
  List<String> categories = [];
  List<dynamic>? providers = [];

  @override
  void initState() {
    super.initState();
    getData();
  }

  fetchFavorites() async {
    setState(() {
      favorites = [];
    });

    var response = await http.get(
        Uri.parse("${Config.api}/favorites/list?id=${user![0]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        for (var favorite in json.decode(response.body)) {
          if (favorite["origin"] == widget.origin) {
            favorites.add(favorite["idContent"]);
          }
        }
        _isLoading = false;
      });
    }
  }

  addFavorite(content) async {
    setState(() {
      _isLoading = true;
    });

    var body = jsonEncode(
        {"idUser": user![0], "idContent": content, 'origin': widget.origin});
    var response = await http
        .post(Uri.parse("${Config.api}/favorites/add"), body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json",
      "Authorization": token!
    });
    if (response.statusCode == 200) {
      setState(() {
        fetchFavorites();
        showInSnackBar('Adicionado aos favoritos com sucesso.');
      });
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

  removeFavorite(content) async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.delete(
        Uri.parse(
            "${Config.api}/favorites/delete?user=${user![0]}&content=$content&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });

    if (response.statusCode == 200) {
      setState(() {
        fetchFavorites();
        showInSnackBar('Removido dos favoritos com sucesso.');
      });
    }
  }

  fetchTriggersFavorites() async {
    var response = await http.get(
        Uri.parse("${Config.api}/triggers_favorites/list?id=${user![0]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        triggerFavorites = json.decode(response.body).cast<int>();
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load Favorites');
    }
  }

  addTriggerFavorite(trigger) async {
    setState(() {
      _isLoading = true;
    });

    var body = jsonEncode({"id_user": user![0], "id_trigger": trigger});
    var response = await http.post(
        Uri.parse("${Config.api}/triggers_favorites/add"),
        body: body,
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        fetchTriggersFavorites();
        showInSnackBar('Adicionado aos favoritos com sucesso.');
      });
    }
  }

  removeTriggerFavorite(trigger) async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.delete(
        Uri.parse(
            "${Config.api}/triggers_favorites/delete?user=${user![0]}&id=$trigger"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        fetchTriggersFavorites();
        showInSnackBar('Removido dos favoritos com sucesso.');
      });
    }
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    await fetchTriggers();
    await fetchFavorites();
    await fetchTriggersFavorites();
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
    var response = await http.get(
        Uri.parse(
            "${Config.api}/triggers/content?id=${widget.movie.id}&user=${user![0]}&origin=${widget.origin}&all=0"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        triggers = List<Trigger>.from(json
            .decode(response.body)
            .map((x) => Trigger.fromJson(x['trigger'])));
      });
    } else {
      throw Exception('Failed to load Feedbacks');
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
                      colors: [Config.secondaryColor!, Config.primaryColor!],
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
                          triggerFavorites.contains(triggers[index].id)
                              ? removeTriggerFavorite(triggers[index].id)
                              : addTriggerFavorite(triggers[index].id);
                        },
                        child: SizedBox(
                          height: 30,
                          width: 30,
                          child: Icon(
                            triggerFavorites.contains(triggers[index].id)
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
      bool aFavoritado = triggerFavorites.contains(a.id);
      bool bFavoritado = triggerFavorites.contains(b.id);

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
                      ? removeFavorite(widget.movie.id)
                      : addFavorite(widget.movie.id);
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
