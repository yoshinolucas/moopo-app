import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/content_list.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/search.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CategoriesContentsList extends StatefulWidget {
  final String name;
  final int movie;
  final int serie;
  final String selected;
  CategoriesContentsList(
      {super.key,
      required this.name,
      required this.movie,
      required this.serie,
      this.selected = 'Filmes'});

  @override
  State<CategoriesContentsList> createState() => _CategoriesContentsListState();
}

class _CategoriesContentsListState extends State<CategoriesContentsList> {
  int _indexMovie = -1;
  int _indexAnime = -1;
  int _indexSerie = -1;
  bool _isLoaded = false;
  bool _isLoading = false;
  String msgSnackbar = "";
  List<String>? user;
  String? token;
  List<Content>? movies = [];
  List<Content>? animes = [];
  List<Content>? series = [];
  List<int>? favoritesMovies = [];
  List<int>? favoritesSeries = [];
  List<int>? favoritesAnimes = [];
  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;
  String _selected = "Filmes";

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
    getData();
  }

  void showInSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msgSnackbar),
        duration: const Duration(milliseconds: 3600),
      ),
    );
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
        _indexMovie = -1;
        _indexAnime = -1;
        _indexSerie = -1;
      });
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
      setState(() {
        msgSnackbar = 'Adicionado aos favoritos com sucesso.';
      });
      showInSnackBar();
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
      setState(() {
        msgSnackbar = 'Removido dos favoritos com sucesso.';
      });
      showInSnackBar();
    }
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    movies = await ContentRepository.fetchContentsByGenre(
        widget.movie, Config.movie);
    animes = await ContentRepository.fetchContentsByGenre(
        widget.serie, Config.anime);
    series = await ContentRepository.fetchContentsByGenre(
        widget.serie, Config.serie);
    await fetchFavorites();
    setState(() {
      _isLoaded = true;
    });
  }

  renderMovies() {
    return GridView.builder(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisExtent: _heigthCard + 58,
          crossAxisCount: MediaQuery.of(context).size.width < 420
              ? 3
              : MediaQuery.of(context).size.width < 700
                  ? 6
                  : MediaQuery.of(context).size.width < 1200
                      ? 9
                      : MediaQuery.of(context).size.width < 1700
                          ? 12
                          : 20,
        ),
        itemCount: movies!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ContentPage(movie: movies![index], origin: 3)));
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
                    _isLoading && _indexMovie == movies![index].id
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
                              setState(() {
                                _indexMovie = movies![index].id;
                              });
                              favoritesMovies!.contains(movies![index].id)
                                  ? removeFavorite(movies![index].id, 3)
                                  : addFavorite(movies![index].id, 3);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.black87.withOpacity(0.3)),
                              height: _sizeFavIcon,
                              width: _sizeFavIcon,
                              child: Icon(
                                favoritesMovies!.contains(movies![index].id)
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
                      height: 54,
                      child: Text(
                        movies![index].title.length > 21
                            ? "${movies![index].title.substring(0, 22)}..."
                            : movies![index].title,
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
          );
        });
  }

  renderAnimes() {
    return GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        physics: const ScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisExtent: _heigthCard + 58,
          crossAxisCount: MediaQuery.of(context).size.width < 420
              ? 3
              : MediaQuery.of(context).size.width < 700
                  ? 6
                  : MediaQuery.of(context).size.width < 1200
                      ? 9
                      : MediaQuery.of(context).size.width < 1700
                          ? 12
                          : 20,
        ),
        itemCount: animes!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ContentPage(movie: animes![index], origin: 3)));
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
                    _isLoading && _indexAnime == animes![index].id
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
                              setState(() {
                                _indexAnime = animes![index].id;
                              });
                              favoritesAnimes!.contains(animes![index].id)
                                  ? removeFavorite(animes![index].id, 3)
                                  : addFavorite(animes![index].id, 3);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.black87.withOpacity(0.3)),
                              height: _sizeFavIcon,
                              width: _sizeFavIcon,
                              child: Icon(
                                favoritesAnimes!.contains(animes![index].id)
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
                      height: 54,
                      child: Text(
                        animes![index].title.length > 21
                            ? "${animes![index].title.substring(0, 22)}..."
                            : animes![index].title,
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
          );
        });
  }

  renderSeries() {
    return GridView.builder(
        physics: const ScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          mainAxisExtent: _heigthCard + 58,
          crossAxisCount: MediaQuery.of(context).size.width < 420
              ? 3
              : MediaQuery.of(context).size.width < 700
                  ? 6
                  : MediaQuery.of(context).size.width < 1200
                      ? 9
                      : MediaQuery.of(context).size.width < 1700
                          ? 12
                          : 20,
        ),
        itemCount: series!.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(2.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ContentPage(movie: series![index], origin: 2)));
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
                    _isLoading && _indexSerie == series![index].id
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
                              setState(() {
                                _indexSerie = series![index].id;
                              });
                              favoritesSeries!.contains(series![index].id)
                                  ? removeFavorite(series![index].id, 2)
                                  : addFavorite(series![index].id, 2);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: Colors.black87.withOpacity(0.3)),
                              height: _sizeFavIcon,
                              width: _sizeFavIcon,
                              child: Icon(
                                favoritesSeries!.contains(series![index].id)
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
                      height: 54,
                      child: Text(
                        series![index].title.length > 21
                            ? "${series![index].title.substring(0, 22)}..."
                            : series![index].title,
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
          );
        });
  }

  List<dynamic> types = [
    {
      "type": "Filmes",
    },
    {"type": "Animes"},
    {"type": "Séries"}
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.name),
        leading: InkWell(
          child: const Icon(
            Icons.arrow_back_ios,
            size: 18,
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
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
              child: Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: types.length,
                          itemBuilder: (context, indexType) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                        shadowColor: MaterialStatePropertyAll(
                                          const Color.fromARGB(
                                                  255, 187, 187, 187)
                                              .withOpacity(0.8),
                                        ),
                                        backgroundColor:
                                            MaterialStatePropertyAll(
                                                _selected ==
                                                        types[indexType]["type"]
                                                    ? Config.primaryColor
                                                    : Colors.white)),
                                    onPressed: () {
                                      setState(() {
                                        _selected = types[indexType]["type"];
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                              types[indexType]["type"] ==
                                                      "Filmes"
                                                  ? Icons.movie
                                                  : types[indexType]["type"] ==
                                                          "Animes"
                                                      ? Icons.smart_toy_outlined
                                                      : Icons
                                                          .local_movies_sharp,
                                              color: _selected ==
                                                      types[indexType]["type"]
                                                  ? Colors.white
                                                  : Config.primaryColor),
                                          const SizedBox(
                                            width: 4,
                                          ),
                                          Text(
                                            types[indexType]["type"],
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _selected ==
                                                        types[indexType]["type"]
                                                    ? Colors.white
                                                    : Config.primaryColor),
                                          )
                                        ],
                                      ),
                                    )),
                              ),
                            );
                          }),
                    ),
                    _selected == "Filmes"
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 12, top: 8, bottom: 8),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
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
                          )
                        : _selected == "Animes"
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, top: 8, bottom: 8),
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
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
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
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 12, top: 8, bottom: 8),
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
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
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
                    _selected == "Filmes"
                        ? renderMovies()
                        : _selected == "Animes"
                            ? renderAnimes()
                            : renderSeries()
                  ],
                ),
              ),
            )
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
      bottomNavigationBar: const Footer(current: 3),
    );
  }
}
