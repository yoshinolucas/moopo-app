import 'dart:async';
import 'dart:convert';

import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/content_list.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/trigger_content_list.dart';
import 'package:app_movie/pages/triggers.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:app_movie/repositories/trigger_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  int selected = Config.all;
  final searchText = TextEditingController();
  List<Content>? contents;

  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;
  List<String>? user;
  String? token;
  bool _isLoading = false;

  List<int>? favoritesMovies = [];
  List<int>? favoritesSeries = [];

  List<int>? favoritesAnimes = [];

  List<Content>? movies = [];
  List<Content>? series = [];
  List<Content>? animes = [];
  List<Trigger>? triggers = [];

  List<Trigger> triggersFavorites = [];
  List<String> triggersFavoritesString = [];

  int _indexMovie = -1;
  int _indexAnime = -1;
  int _indexSerie = -1;

  bool _isSearched = false;

  int selectedIndex = 0;

  FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    getData();
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    await fetchFavorites();
    await fetchFavoritesTriggers();
    fetchSearch("");
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

  void showInSnackBar(msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: Colors.white)),
        duration: const Duration(milliseconds: 3600),
        backgroundColor: Config.primaryColor,
      ),
    );
  }

  reset() {
    setState(() {
      _indexAnime = -1;
      _indexSerie = -1;
      _indexMovie = -1;
    });
  }

  renderTriggers() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Triggers(
                        triggers: [],
                      ),
                    ));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Gatilhos",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: triggers!.length > 0
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width < 650
                          ? 2
                          : MediaQuery.of(context).size.width < 1080
                              ? 4
                              : 6,
                      childAspectRatio: (1 / .4),
                    ),
                    itemCount: triggers!.length,
                    itemBuilder: (context, index) => InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TriggerContentList(
                                    trigger: triggers![index].id,
                                    name: triggers![index].name)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
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
                                    Config.primaryColor
                                  ],
                                )),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Text(
                                    utf8.decode(
                                        latin1.encode(triggers![index].name)),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )),
                            _isLoading
                                ? const SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: Padding(
                                      padding: EdgeInsets.all(0),
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ))
                                : InkWell(
                                    onTap: () {
                                      triggersFavoritesString
                                              .contains(triggers![index].id)
                                          ? removeFavoriteTrigger(
                                              triggers![index].id)
                                          : addFavoriteTrigger(
                                              triggers![index].id);
                                    },
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: Icon(
                                        triggersFavoritesString
                                                .contains(triggers![index].id)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.white,
                                      ),
                                    ))
                          ]),
                        ),
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text("Nenhum gatilho encontrado"),
                  ),
          ),
        ],
      ),
    );
  }

  renderMovies() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContentList(type: Config.movie),
                  ),
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Filmes",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          movies!.length > 0
              ? SizedBox(
                  height: _heigthCard + 72,
                  width: double.infinity,
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: movies!.length,
                      itemBuilder: (context, index) {
                        return (movies![index].posterPath == "")
                            ? const SizedBox()
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: 12,
                                    right:
                                        index == movies!.length - 1 ? 12 : 0),
                                child: Column(children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ContentPage(
                                                  movie: movies![index],
                                                  origin: Config.movie)));
                                    },
                                    child: Column(
                                      children: [
                                        Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(4),
                                                        topRight:
                                                            Radius.circular(4)),
                                                child: Image.network(
                                                    movies![index].posterPath,
                                                    fit: BoxFit.cover,
                                                    height: _heigthCard,
                                                    width: _widthCard,
                                                    gaplessPlayback: true),
                                              ),
                                              _isLoading &&
                                                      _indexAnime ==
                                                          movies![index].id
                                                  ? SizedBox(
                                                      height: _sizeFavIcon,
                                                      width: _sizeFavIcon,
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
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
                                                              movies![index].id;
                                                        });
                                                        favoritesMovies!.contains(
                                                                movies![index]
                                                                    .id)
                                                            ? removeFavorite(
                                                                movies![index]
                                                                    .id,
                                                                Config.movie)
                                                            : addFavorite(
                                                                movies![index]
                                                                    .id,
                                                                Config.movie);
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            color: Colors
                                                                .black87
                                                                .withOpacity(
                                                                    0.3)),
                                                        height: _sizeFavIcon,
                                                        width: _sizeFavIcon,
                                                        child: Icon(
                                                          favoritesMovies!.contains(
                                                                  movies![index]
                                                                      .id)
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border_outlined,
                                                          color: Colors.white,
                                                          size: _sizeFavIcon -
                                                              3.5,
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
                                ]),
                              );
                      }),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text("Nenhum filme encontrado"),
                ),
        ],
      ),
    );
  }

  renderSeries() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
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
                InkWell(
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
                      Icon(
                        Icons.arrow_back_ios_sharp,
                        size: 17,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Text("Animes",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 12,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          series!.length > 0
              ? SizedBox(
                  height: _heigthCard + 72,
                  width: double.infinity,
                  child: ListView.builder(
                      physics: const ClampingScrollPhysics(),
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      itemCount: series!.length,
                      itemBuilder: (context, index) {
                        return (series![index].posterPath == "")
                            ? const SizedBox()
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: 12,
                                    right:
                                        index == series!.length - 1 ? 12 : 0),
                                child: Column(children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ContentPage(
                                                  movie: series![index],
                                                  origin: series![index]
                                                              .original_language ==
                                                          "ja"
                                                      ? Config.anime
                                                      : Config.serie)));
                                    },
                                    child: Column(
                                      children: [
                                        Stack(
                                            alignment: Alignment.topRight,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(4),
                                                        topRight:
                                                            Radius.circular(4)),
                                                child: Image.network(
                                                    series![index].posterPath,
                                                    fit: BoxFit.cover,
                                                    height: _heigthCard,
                                                    width: _widthCard,
                                                    gaplessPlayback: true),
                                              ),
                                              _isLoading &&
                                                      _indexAnime ==
                                                          series![index].id
                                                  ? SizedBox(
                                                      height: _sizeFavIcon,
                                                      width: _sizeFavIcon,
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(4.0),
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
                                                              series![index].id;
                                                        });
                                                        favoritesSeries!.contains(
                                                                series![index]
                                                                    .id)
                                                            ? removeFavorite(
                                                                series![index]
                                                                    .id,
                                                                series![index].original_language ==
                                                                        "ja"
                                                                    ? Config
                                                                        .anime
                                                                    : Config
                                                                        .serie)
                                                            : addFavorite(
                                                                series![index]
                                                                    .id,
                                                                series![index].original_language ==
                                                                        "ja"
                                                                    ? Config
                                                                        .anime
                                                                    : Config
                                                                        .serie);
                                                      },
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                            color: Colors
                                                                .black87
                                                                .withOpacity(
                                                                    0.3)),
                                                        height: _sizeFavIcon,
                                                        width: _sizeFavIcon,
                                                        child: Icon(
                                                          favoritesSeries!.contains(
                                                                  series![index]
                                                                      .id)
                                                              ? Icons.star
                                                              : Icons
                                                                  .star_border_outlined,
                                                          color: Colors.white,
                                                          size: _sizeFavIcon -
                                                              3.5,
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
                                ]),
                              );
                      }),
                )
              : Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text("Nenhuma mídia encontrada"),
                ),
        ],
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  Timer? _debounceTimer;
  void fetchSearch(String txt) async {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _isSearched = false;
      });
      List<Content>? moviesResult;
      List<Content>? seriesResult;
      List<Content>? animesResult;
      if (searchText.text.isNotEmpty) {
        moviesResult = await ContentRepository.fetchContentsBySearch(
            searchText.text, Config.movie);
        seriesResult = await ContentRepository.fetchContentsBySearch(
            searchText.text, Config.serie);
        animesResult = await ContentRepository.fetchContentsBySearch(
            searchText.text, Config.anime);
      } else {
        moviesResult = await ContentRepository.fetchContents(1, Config.movie);
        seriesResult = await ContentRepository.fetchContents(1, Config.serie);
        animesResult = await ContentRepository.fetchContents(1, Config.anime);
      }

      var triggersResultDb = await db
          .collection("triggers")
          .orderBy("name")
          .startAt([capitalize(searchText.text)])
          .endAt([capitalize(searchText.text) + '\uf8ff'])
          .limit(selectedIndex == 2 ? 20 : 4)
          .get();

      List<Trigger>? triggersResult = triggersResultDb.docs.map((e) {
        var data = {
          "id": e.id,
          "name": e.get("name"),
          "description": e.get("description")
        };
        return Trigger.fromJson(data);
      }).toList();

      setState(() {
        movies = moviesResult;
        series = seriesResult;
        animes = animesResult;
        triggers = triggersResult;
        _isSearched = true;
      });
    });
  }

  renderMoviesGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentList(type: Config.movie),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Filmes",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
        movies!.length > 0
            ? GridView.builder(
                physics: const ScrollPhysics(),
                shrinkWrap: true,
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
                  return (movies![index].posterPath == "")
                      ? const SizedBox()
                      : Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ContentPage(
                                          movie: movies![index],
                                          origin: Config.movie)));
                            },
                            child: Column(
                              children: [
                                Stack(alignment: Alignment.topRight, children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4)),
                                    child: Image.network(
                                        movies![index].posterPath,
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
                                            favoritesMovies!
                                                    .contains(movies![index].id)
                                                ? removeFavorite(
                                                    movies![index].id,
                                                    Config.movie)
                                                : addFavorite(movies![index].id,
                                                    Config.movie);
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
                                              favoritesMovies!.contains(
                                                      movies![index].id)
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
                })
            : Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text("Nenhum filme encontrado"),
              ),
      ],
    );
  }

  renderSeriesGrid() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
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
                InkWell(
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
                      Icon(
                        Icons.arrow_back_ios_sharp,
                        size: 17,
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Text("Animes",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 12,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          series!.length > 0
              ? GridView.builder(
                  physics: const ScrollPhysics(),
                  shrinkWrap: true,
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
                    return (series![index].posterPath == "")
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ContentPage(
                                            movie: series![index],
                                            origin: series![index]
                                                        .original_language ==
                                                    "ja"
                                                ? Config.anime
                                                : Config.serie)));
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
                                              series![index].posterPath,
                                              fit: BoxFit.cover,
                                              height: _heigthCard,
                                              width: _widthCard,
                                              gaplessPlayback: true),
                                        ),
                                        _isLoading &&
                                                _indexSerie == series![index].id
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
                                                  setState(() {
                                                    _indexSerie =
                                                        series![index].id;
                                                  });
                                                  favoritesSeries!.contains(
                                                          series![index].id)
                                                      ? removeFavorite(
                                                          series![index].id,
                                                          series![index]
                                                                      .original_language ==
                                                                  "ja"
                                                              ? Config.anime
                                                              : Config.serie)
                                                      : addFavorite(
                                                          series![index].id,
                                                          series![index]
                                                                      .original_language ==
                                                                  "ja"
                                                              ? Config.anime
                                                              : Config.serie);
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
                                                            series![index].id)
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
                  })
              : Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text("Nenhuma mídia encontrada"),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: InkWell(
            child: const Icon(
              Icons.arrow_back_ios,
              size: 18,
              color: Colors.black54,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchText,
                onChanged: fetchSearch,
                cursorColor: Config.primaryColor,
                decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      size: 16,
                      color: Config.primaryColor,
                    ),
                    contentPadding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                    border: InputBorder.none,
                    hintText: 'Pesquisar...'),
              ),
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(45.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                  indicatorColor: Config.primaryColor,
                  onTap: (index) async {
                    List<Trigger>? triggersResult;
                    if (index == 1) {
                      triggersResult =
                          await TriggerRepository.getTriggersBySearch(
                              searchText.text, 20);
                    } else {
                      triggersResult =
                          await TriggerRepository.getTriggersBySearch(
                              searchText.text, 4);
                    }

                    setState(() {
                      triggers = triggersResult;
                      selectedIndex = index;
                    });
                  },
                  unselectedLabelColor: Colors.black54,
                  labelColor: Colors.black,
                  isScrollable: true,
                  tabs: [
                    Tab(
                      child: Text(
                        'Tudo',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Gatilhos',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Filmes',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Tab(
                      child: Text(
                        'Séries & Animes',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
        body: _isSearched
            ? TabBarView(physics: NeverScrollableScrollPhysics(), children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      renderTriggers(),
                      renderMovies(),
                      renderSeries()
                    ],
                  ),
                ),
                SingleChildScrollView(child: renderTriggers()),
                SingleChildScrollView(
                  child: renderMoviesGrid(),
                ),
                SingleChildScrollView(
                  child: renderSeriesGrid(),
                )
              ])
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
        bottomNavigationBar: const Footer(
          current: 0,
        ),
      ),
    );
  }
}
