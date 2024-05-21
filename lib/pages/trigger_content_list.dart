import 'dart:async';
import 'dart:convert';

import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/content_list.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/search.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TriggerContentList extends StatefulWidget {
  final String trigger;
  final String name;
  const TriggerContentList(
      {super.key, required this.trigger, required this.name});

  @override
  State<TriggerContentList> createState() => _TriggerContentListState();
}

class _TriggerContentListState extends State<TriggerContentList> {
  bool _isLoaded = true;
  bool _isLoading = false;
  List<Content>? movies = [];
  List<Content>? series = [];
  List<Content>? animes = [];

  List<String>? user;
  String? token;

  List<int>? favoritesMovies = [];
  List<int>? favoritesSeries = [];
  List<int>? favoritesAnimes = [];

  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getData();
  }

  fetchContents() async {
    var triggersDb = await db
        .collection("triggers_content")
        .where("trigger", isEqualTo: widget.trigger)
        .get();

    if (triggersDb.docs.isNotEmpty) {
      Future.forEach(triggersDb.docs, (element) async {
        if (element.get("origin") == Config.movie) {
          Content movie = await ContentRepository.fetchContentById(
              element.get("content"), Config.movie);
          setState(() {
            movies!.add(movie);
          });
        }
        if (element.get("origin") == Config.serie) {
          Content serie = await ContentRepository.fetchContentById(
              element.get("content"), Config.serie);
          setState(() {
            series!.add(serie);
          });
        }
        if (element.get("origin") == Config.anime) {
          Content anime = await ContentRepository.fetchContentById(
              element.get("content"), Config.anime);
          setState(() {
            animes!.add(anime);
          });
        }
      });
    }
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    await fetchContents();
    await fetchFavorites();
    // setState(() {
    //   _isLoaded = true;
    // });
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
      // _indexMovie = -1;
      // _indexAnime = -1;
      // _indexSerie = -1;
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

  renderMovies() {
    return movies!.isEmpty
        ? const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text("Nenhum filme encontrado"),
          )
        : SizedBox(
            height: _heigthCard + 72,
            width: double.infinity,
            child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: movies!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                        left: 12, right: index == movies!.length - 1 ? 12 : 0),
                    child: Column(children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContentPage(
                                      movie: movies![index], origin: 1)));
                        },
                        child: Column(
                          children: [
                            Stack(alignment: Alignment.topRight, children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4)),
                                child: Image.network(movies![index].posterPath,
                                    fit: BoxFit.cover,
                                    height: _heigthCard,
                                    width: _widthCard,
                                    gaplessPlayback: true),
                              ),
                              _isLoading
                                  ? SizedBox(
                                      height: _sizeFavIcon,
                                      width: _sizeFavIcon,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ))
                                  : InkWell(
                                      onTap: () {
                                        favoritesMovies!
                                                .contains(movies![index].id)
                                            ? removeFavorite(
                                                movies![index].id, 1)
                                            : addFavorite(movies![index].id, 1);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Colors.black87
                                                .withOpacity(0.3)),
                                        height: _sizeFavIcon,
                                        width: _sizeFavIcon,
                                        child: Icon(
                                          favoritesMovies!
                                                  .contains(movies![index].id)
                                              ? Icons.star
                                              : Icons.star_border_outlined,
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
                                height: 64,
                                child: Text(
                                  movies![index].title.length > 21
                                      ? "${movies![index].title.substring(0, 22)}..."
                                      : movies![index].title,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
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
          );
  }

  renderAnimes() {
    return animes!.isEmpty
        ? const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text("Nenhum anime encontrado"),
          )
        : SizedBox(
            height: _heigthCard + 72,
            width: double.infinity,
            child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: animes!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                        left: 12, right: index == animes!.length - 1 ? 12 : 0),
                    child: Column(children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContentPage(
                                      movie: animes![index], origin: 3)));
                        },
                        child: Column(
                          children: [
                            Stack(alignment: Alignment.topRight, children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4)),
                                child: Image.network(animes![index].posterPath,
                                    fit: BoxFit.cover,
                                    height: _heigthCard,
                                    width: _widthCard,
                                    gaplessPlayback: true),
                              ),
                              _isLoading
                                  ? SizedBox(
                                      height: _sizeFavIcon,
                                      width: _sizeFavIcon,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ))
                                  : InkWell(
                                      onTap: () {
                                        favoritesAnimes!
                                                .contains(animes![index].id)
                                            ? removeFavorite(
                                                animes![index].id, 3)
                                            : addFavorite(animes![index].id, 3);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Colors.black87
                                                .withOpacity(0.3)),
                                        height: _sizeFavIcon,
                                        width: _sizeFavIcon,
                                        child: Icon(
                                          favoritesAnimes!
                                                  .contains(animes![index].id)
                                              ? Icons.star
                                              : Icons.star_border_outlined,
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
                                height: 64,
                                child: Text(
                                  animes![index].title.length > 21
                                      ? "${animes![index].title.substring(0, 22)}..."
                                      : animes![index].title,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
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
          );
  }

  renderSeries() {
    return series!.isEmpty
        ? const Padding(
            padding: EdgeInsets.only(left: 12.0, bottom: 24),
            child: Text("Nenhuma série encontrada"),
          )
        : SizedBox(
            height: _heigthCard + 72,
            width: double.infinity,
            child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: series!.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                        left: 12, right: index == series!.length - 1 ? 12 : 0),
                    child: Column(children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ContentPage(
                                      movie: series![index], origin: 2)));
                        },
                        child: Column(
                          children: [
                            Stack(alignment: Alignment.topRight, children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4)),
                                child: Image.network(series![index].posterPath,
                                    fit: BoxFit.cover,
                                    height: _heigthCard,
                                    width: _widthCard,
                                    gaplessPlayback: true),
                              ),
                              _isLoading
                                  ? SizedBox(
                                      height: _sizeFavIcon,
                                      width: _sizeFavIcon,
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ))
                                  : InkWell(
                                      onTap: () {
                                        favoritesSeries!
                                                .contains(series![index].id)
                                            ? removeFavorite(
                                                series![index].id, 2)
                                            : addFavorite(series![index].id, 2);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            color: Colors.black87
                                                .withOpacity(0.3)),
                                        height: _sizeFavIcon,
                                        width: _sizeFavIcon,
                                        child: Icon(
                                          favoritesSeries!
                                                  .contains(series![index].id)
                                              ? Icons.star
                                              : Icons.star_border_outlined,
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
                                height: 64,
                                child: Text(
                                  series![index].title.length > 21
                                      ? "${series![index].title.substring(0, 22)}..."
                                      : series![index].title,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
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
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16))),
        title: Text(utf8.decode(latin1.encode(widget.name))),
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
              child: Padding(
              padding: const EdgeInsets.only(top: 90.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ContentList(
                                        type: Config.movie,
                                      )));
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Filmes",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 4,
                            ),
                            Icon(
                              Icons.arrow_forward_ios_sharp,
                              size: 17,
                            )
                          ],
                        ),
                      ),
                    ),
                    renderMovies(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ContentList(
                                        type: Config.anime,
                                      )));
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Animes",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 4,
                            ),
                            Icon(
                              Icons.arrow_forward_ios_sharp,
                              size: 17,
                            )
                          ],
                        ),
                      ),
                    ),
                    renderAnimes(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ContentList(
                                        type: Config.serie,
                                      )));
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Séries",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 4,
                            ),
                            Icon(
                              Icons.arrow_forward_ios_sharp,
                              size: 17,
                            )
                          ],
                        ),
                      ),
                    ),
                    renderSeries()
                  ]),
            ))
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
