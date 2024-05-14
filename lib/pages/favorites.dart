import 'dart:async';
import 'dart:convert';

import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/search.dart';
import 'package:app_movie/pages/trigger_content_list.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> triggersFavoritesString = [];
  FirebaseFirestore db = FirebaseFirestore.instance;

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
    var favorites = await db
        .collection("favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .get();

    if (favorites.docs.isNotEmpty) {
      setState(() {
        favorites.docs.forEach((favorite) {
          if (favorite.get("origin") == Config.movie) {
            favoritesMovies!.add(favorite["idContent"]);
          }
          if (favorite.get("origin") == Config.serie) {
            favoritesSeries!.add(favorite["idContent"]);
          }
          if (favorite.get("origin") == Config.anime) {
            favoritesAnimes!.add(favorite["idContent"]);
          }
        });
      });
    }

    setState(() {
      _isLoading = false;
      _indexMovie = -1;
      _indexAnime = -1;
      _indexSerie = -1;
    });
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

  fetchTriggers() async {
    Query<Map<String, dynamic>> query = db.collection("triggers");
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
        triggersFavorites = result
            .where((t) => triggersFavoritesString.contains(t.id))
            .toList();
      });
    }
    setState(() {
      _isLoaded = true;
    });
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

    fetchFavoritesTriggers();
    showInSnackBar('Removido dos favoritos com sucesso.');
  }

  addFavoriteTrigger(trigger) async {
    setState(() {
      _isLoading = true;
    });
    var body = {'idUser': user![Config.id], 'idTrigger': trigger};
    db.collection("triggers_favorites").add(body).then((value) {
      fetchFavoritesTriggers();
      showInSnackBar('Adicionado aos favoritos com sucesso.');
    });
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
                                      triggersFavoritesString.contains(
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
                                        triggersFavoritesString.contains(
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
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              )),
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
