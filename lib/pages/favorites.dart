import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/search.dart';
import 'package:app_movie/pages/trigger_content_list.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;
  List<String>? user;
  String? token;
  bool _isLoaded = true;
  bool _isLoading = false;
  List<Content> movies = [];
  List<Content> series = [];
  List<Content> animes = [];
  List<int>? favoritesMovies = [];
  List<int>? favoritesSeries = [];
  List<int>? favoritesAnimes = [];

  List<Trigger> triggersFavorites = [];
  List<int> triggersFavoritesInt = [];

  int _indexMovie = -1;
  int _indexAnime = -1;
  int _indexSerie = -1;

  @override
  void initState() {
    super.initState();
    getData();
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

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    await fetchFavorites();
    await fetchMovies();
    await fetchSeries();
    await fetchAnimes();
    await fetchFavoritesTriggers();
    await fetchTriggers();
  }

  fetchMovies() async {
    if (favoritesMovies != null) {
      for (var item in favoritesMovies!) {
        try {
          Content movie =
              await ContentRepository.fetchContentById(item, Config.movie);
          setState(() {
            movies.add(movie);
          });
        } catch (e) {
          continue;
        }
      }
    }
  }

  fetchSeries() async {
    if (favoritesSeries != null) {
      for (var item in favoritesSeries!) {
        try {
          Content serie =
              await ContentRepository.fetchContentById(item, Config.serie);
          setState(() {
            series.add(serie);
          });
        } catch (e) {
          continue;
        }
      }
    }
  }

  fetchAnimes() async {
    if (favoritesAnimes != null) {
      for (var item in favoritesAnimes!) {
        try {
          Content anime =
              await ContentRepository.fetchContentById(item, Config.anime);
          setState(() {
            animes.add(anime);
          });
        } catch (e) {
          continue;
        }
      }
    }
  }

  fetchFavorites() async {
    setState(() {
      favoritesMovies = [];
      favoritesSeries = [];
      favoritesAnimes = [];
    });
    var response = await http.get(
        Uri.parse("${Config.api}/favorites/list?id=${user![Config.id]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        for (var favorite in json.decode(response.body)) {
          if (favorite["origin"] == Config.movie) {
            favoritesMovies!.add(favorite["idContent"]);
          }
          if (favorite["origin"] == Config.serie) {
            favoritesSeries!.add(favorite["idContent"]);
          }
          if (favorite["origin"] == Config.anime) {
            favoritesAnimes!.add(favorite["idContent"]);
          }
        }
        _isLoading = false;
      });
    }
  }

  fetchFavoritesTriggers() async {
    var response = await http.get(
        Uri.parse(
            "${Config.api}/triggers_favorites/list?id=${user![Config.id]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        triggersFavoritesInt = json.decode(response.body).cast<int>();
        _isLoading = false;
      });
      fetchTriggers();
    } else {
      throw Exception('Failed to load Favorites');
    }
  }

  fetchTriggers() async {
    var response = await http.post(
        Uri.parse("${Config.api}/triggers/all?page=1&limit=20"),
        body: json.encode({"search": "", "order": "id"}),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      List<Trigger> result = List<Trigger>.from(
          json.decode(response.body).map((x) => Trigger.fromJson(x)));
      setState(() {
        triggersFavorites =
            result.where((t) => triggersFavoritesInt.contains(t.id)).toList();
        _isLoaded = true;
      });
    } else {
      throw Exception('Failed to load Triggers');
    }
  }

  removeFavoriteTrigger(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var response = await http.delete(
        Uri.parse(
            "${Config.api}/triggers_favorites/delete?user=${user![Config.id]}&id=$trigger"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchFavoritesTriggers();
      showInSnackBar('Removido dos favoritos com sucesso.');
    }
  }

  addFavoriteTrigger(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var body = jsonEncode({'id_user': user![Config.id], 'id_trigger': trigger});
    var response = await http.post(
        Uri.parse("${Config.api}/triggers_favorites/add"),
        body: body,
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchFavoritesTriggers();
      showInSnackBar('Adicionado aos favoritos com sucesso.');
    }
  }

  addFavorite(content, origin) async {
    setState(() {
      _isLoading = true;
    });
    var body = jsonEncode(
        {'idUser': user![Config.id], 'idContent': content, 'origin': origin});
    var response = await http
        .post(Uri.parse("${Config.api}/favorites/add"), body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json",
      "Authorization": token!
    });
    if (response.statusCode == 200) {
      fetchFavorites();
      showInSnackBar('Adicionado aos favoritos com sucesso.');
    }
  }

  removeFavorite(content, origin) async {
    setState(() {
      _isLoading = true;
    });
    var response = await http.delete(
        Uri.parse(
            "${Config.api}/favorites/delete?user=${user![Config.id]}&content=$content&origin=$origin"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchFavorites();
      showInSnackBar('Removido dos favoritos com sucesso.');
    }
  }

  reset() {
    setState(() {
      _indexAnime = -1;
      _indexSerie = -1;
      _indexMovie = -1;
    });
  }

  renderFavorites() {
    return Padding(
      padding: const EdgeInsets.only(top: 85.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 10.0),
            child: Text(
              "Meus gatilhos",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          triggersFavorites.isEmpty
              ? const Column(
                  children: [
                    SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Nenhum gatilho favoritado"),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: GridView.builder(
                    shrinkWrap: true,
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
                    itemBuilder: (context, index) => InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TriggerContentList(
                                    trigger: triggersFavorites[index].id,
                                    name: triggersFavorites[index].name)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                                    utf8.decode(latin1
                                        .encode(triggersFavorites[index].name)),
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
                                      triggersFavoritesInt.contains(
                                              triggersFavorites[index].id)
                                          ? removeFavoriteTrigger(
                                              triggersFavorites[index].id)
                                          : addFavoriteTrigger(
                                              triggersFavorites[index].id);
                                    },
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: Icon(
                                        triggersFavoritesInt.contains(
                                                triggersFavorites[index].id)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.white,
                                      ),
                                    ))
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Text(
              "Meus filmes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          movies.length > 0
              ? SizedBox(
                  height: _heigthCard + 72,
                  width: double.infinity,
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: movies.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                              left: 12,
                              right: index == movies.length - 1 ? 12 : 0),
                          child: Column(children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ContentPage(
                                            movie: movies[index], origin: 1)));
                              },
                              child: Column(
                                children: [
                                  Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4)),
                                          child: Image.network(
                                              movies[index].posterPath,
                                              fit: BoxFit.cover,
                                              height: _heigthCard,
                                              width: _widthCard,
                                              gaplessPlayback: true),
                                        ),
                                        _isLoading &&
                                                _indexMovie == movies[index].id
                                            ? SizedBox(
                                                height: _sizeFavIcon,
                                                width: _sizeFavIcon,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ))
                                            : InkWell(
                                                onTap: () {
                                                  reset();
                                                  setState(() {
                                                    _indexMovie =
                                                        movies[index].id;
                                                  });
                                                  favoritesMovies!.contains(
                                                          movies[index].id)
                                                      ? removeFavorite(
                                                          movies[index].id, 1)
                                                      : addFavorite(
                                                          movies[index].id, 1);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      color: Colors.black87
                                                          .withOpacity(0.3)),
                                                  height: _sizeFavIcon,
                                                  width: _sizeFavIcon,
                                                  child: Icon(
                                                    favoritesMovies!.contains(
                                                            movies[index].id)
                                                        ? Icons.star
                                                        : Icons
                                                            .star_border_outlined,
                                                    color: Colors.white,
                                                    size: _sizeFavIcon - 3.5,
                                                  ),
                                                ))
                                      ]),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4)),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      color: Colors.black87,
                                      width: _widthCard,
                                      height: 54,
                                      child: Text(
                                        movies[index].title.length > 21
                                            ? "${movies[index].title.substring(0, 22)}..."
                                            : movies[index].title,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                      }),
                )
              : const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Nenhum filme favoritado"),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                  ],
                ),
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Text(
              "Meus Animes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          animes.length > 0
              ? SizedBox(
                  height: _heigthCard + 72,
                  width: double.infinity,
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: animes.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                              left: 12,
                              right: index == animes.length - 1 ? 12 : 0),
                          child: Column(children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ContentPage(
                                            movie: animes[index], origin: 3)));
                              },
                              child: Column(
                                children: [
                                  Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4)),
                                          child: Image.network(
                                              animes[index].posterPath,
                                              fit: BoxFit.cover,
                                              height: _heigthCard,
                                              width: _widthCard,
                                              gaplessPlayback: true),
                                        ),
                                        _isLoading &&
                                                _indexAnime == animes[index].id
                                            ? SizedBox(
                                                height: _sizeFavIcon,
                                                width: _sizeFavIcon,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ))
                                            : InkWell(
                                                onTap: () {
                                                  reset();
                                                  setState(() {
                                                    _indexAnime =
                                                        animes[index].id;
                                                  });
                                                  favoritesAnimes!.contains(
                                                          animes[index].id)
                                                      ? removeFavorite(
                                                          animes[index].id, 3)
                                                      : addFavorite(
                                                          animes[index].id, 3);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      color: Colors.black87
                                                          .withOpacity(0.3)),
                                                  height: _sizeFavIcon,
                                                  width: _sizeFavIcon,
                                                  child: Icon(
                                                    favoritesAnimes!.contains(
                                                            animes[index].id)
                                                        ? Icons.star
                                                        : Icons
                                                            .star_border_outlined,
                                                    color: Colors.white,
                                                    size: _sizeFavIcon - 3.5,
                                                  ),
                                                ))
                                      ]),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4)),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      color: Colors.black87,
                                      width: _widthCard,
                                      height: 54,
                                      child: Text(
                                        animes[index].title.length > 21
                                            ? "${animes[index].title.substring(0, 22)}..."
                                            : animes[index].title,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                      }),
                )
              : const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Nenhum anime favoritado"),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                  ],
                ),
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 8, bottom: 8),
            child: Text(
              "Minhas Séries",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          series.length > 0
              ? SizedBox(
                  height: _heigthCard + 72,
                  width: double.infinity,
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: series.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                              left: 12,
                              right: index == series.length - 1 ? 12 : 0),
                          child: Column(children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ContentPage(
                                            movie: series[index], origin: 2)));
                              },
                              child: Column(
                                children: [
                                  Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              topRight: Radius.circular(4)),
                                          child: Image.network(
                                              series[index].posterPath,
                                              fit: BoxFit.cover,
                                              height: _heigthCard,
                                              width: _widthCard,
                                              gaplessPlayback: true),
                                        ),
                                        _isLoading &&
                                                _indexSerie == series[index].id
                                            ? SizedBox(
                                                height: _sizeFavIcon,
                                                width: _sizeFavIcon,
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ))
                                            : InkWell(
                                                onTap: () {
                                                  reset();
                                                  setState(() {
                                                    _indexSerie =
                                                        series[index].id;
                                                  });
                                                  favoritesSeries!.contains(
                                                          series[index].id)
                                                      ? removeFavorite(
                                                          series[index].id, 2)
                                                      : addFavorite(
                                                          series[index].id, 2);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      color: Colors.black87
                                                          .withOpacity(0.3)),
                                                  height: _sizeFavIcon,
                                                  width: _sizeFavIcon,
                                                  child: Icon(
                                                    favoritesSeries!.contains(
                                                            series[index].id)
                                                        ? Icons.star
                                                        : Icons
                                                            .star_border_outlined,
                                                    color: Colors.white,
                                                    size: _sizeFavIcon - 3.5,
                                                  ),
                                                ))
                                      ]),
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(4),
                                        bottomRight: Radius.circular(4)),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      color: Colors.black87,
                                      width: _widthCard,
                                      height: 54,
                                      child: Text(
                                        series[index].title.length > 21
                                            ? "${series[index].title.substring(0, 22)}..."
                                            : series[index].title,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        );
                      }),
                )
              : const Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text("Nenhuma série favoritado"),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Favoritos"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (contexxt) => const SearchPage()));
              },
              icon: const Icon(Icons.search)),
        ],
      ),
      body: _isLoaded
          ? SingleChildScrollView(
              child: renderFavorites(),
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
      bottomNavigationBar: const Footer(current: 4),
    );
  }
}
