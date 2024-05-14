import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/genre.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/pages/categories_contents_list.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/search.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:app_movie/repositories/genre_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ContentList extends StatefulWidget {
  final int type;
  final List<Content>? contents;
  const ContentList({super.key, required this.type, this.contents});

  @override
  State<ContentList> createState() => _ContentListState();
}

class _ContentListState extends State<ContentList> {
  bool _openCategories = false;

  int _index = -1;
  List<String>? user;
  String? token;

  List<Content>? contents;
  List<Genre>? genres;
  List<int>? favorites = [];

  bool _isLoaded = false;
  bool _isLoading = false;
  String msgSnackbar = '';

  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;

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
        Uri.parse("${Config.api}/favorites/list?id=${user![Config.id]}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        for (var favorite in json.decode(response.body)) {
          favorites!.add(favorite["idContent"]);
        }
        _isLoading = false;
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

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
      token = prefs.getString("token");
    });
    genres = await GenreRepository.fetch(
        widget.type == Config.movie ? 'movie' : 'tv');

    if (widget.contents == null) {
      List<Content>? contents1 =
          await ContentRepository.fetchContents(1, widget.type);
      List<Content>? contents2 =
          await ContentRepository.fetchContents(2, widget.type);
      List<Content>? contents3 =
          await ContentRepository.fetchContents(3, widget.type);
      List<Content>? contents4 =
          await ContentRepository.fetchContents(4, widget.type);
      List<Content>? contents5 =
          await ContentRepository.fetchContents(5, widget.type);
      List<Content>? contents6 =
          await ContentRepository.fetchContents(6, widget.type);

      contents = [
        ...contents1!,
        ...contents2!,
        ...contents3!,
        ...contents4!,
        ...contents5!,
        ...contents6!
      ];
    } else {
      contents = widget.contents;
    }
    await fetchFavorites();
    setState(() {
      _isLoaded = true;
    });
  }

  renderContents() {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 90.0),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.type == Config.movie
                            ? "Filmes"
                            : widget.type == Config.serie
                                ? "Séries"
                                : "Animes",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                          onPressed: () {
                            setState(() {
                              _openCategories = true;
                            });
                          },
                          child: const Row(
                            children: [
                              Text(
                                "Categorias",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black,
                              )
                            ],
                          ))
                    ],
                  ),
                ),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(0),
                shrinkWrap: true,
                itemCount: genres?.length,
                itemBuilder: (context, indexGenre) {
                  // Filtrar os filmes pelo gênero atual
                  final moviesInGenre = contents
                      ?.where((movie) =>
                          movie.genreIds.contains(genres![indexGenre].id))
                      .toList();

                  // Verificar se há filmes no gênero atual
                  if (moviesInGenre != null && moviesInGenre.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 12, top: 8, bottom: 8),
                          child: Text(genres![indexGenre].name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: _heigthCard + 72,
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: moviesInGenre.length,
                            itemBuilder: (context, index) {
                              // Retorne um FILME aqui com base em moviesInGenre[index]
                              return Padding(
                                padding: EdgeInsets.only(
                                    left: 12,
                                    right: index == moviesInGenre.length - 1
                                        ? 12
                                        : 0),
                                child: Column(children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => ContentPage(
                                                  movie: moviesInGenre[index],
                                                  origin: widget.type)));
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
                                                    moviesInGenre[index]
                                                        .posterPath,
                                                    fit: BoxFit.cover,
                                                    height: _heigthCard,
                                                    width: _widthCard,
                                                    gaplessPlayback: true),
                                              ),
                                              _isLoading &&
                                                      _index ==
                                                          moviesInGenre[index]
                                                              .id
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
                                                        setState(() {
                                                          _index =
                                                              moviesInGenre[
                                                                      index]
                                                                  .id;
                                                        });
                                                        favorites!.contains(
                                                                moviesInGenre[
                                                                        index]
                                                                    .id)
                                                            ? removeFavorite(
                                                                moviesInGenre[
                                                                        index]
                                                                    .id,
                                                                widget.type)
                                                            : addFavorite(
                                                                moviesInGenre[
                                                                        index]
                                                                    .id,
                                                                widget.type);
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
                                                          favorites!.contains(
                                                                  moviesInGenre[
                                                                          index]
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
                                              moviesInGenre[index]
                                                          .title
                                                          .length >
                                                      21
                                                  ? "${moviesInGenre[index].title.substring(0, 22)}..."
                                                  : moviesInGenre[index].title,
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
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Se não houver filmes no gênero, retorne um container vazio ou null
                    return const SizedBox.shrink();
                  }
                },
              )
            ],
          ),
        ),
        _openCategories
            ? Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                _openCategories = false;
                              });
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            )),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: Config.genres
                              .map((genre) => ListTile(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  CategoriesContentsList(
                                                      selected: widget.type ==
                                                              Config.movie
                                                          ? "Filmes"
                                                          : widget.type ==
                                                                  Config.serie
                                                              ? "Séries"
                                                              : "Animes",
                                                      name: genre["name"]
                                                          .toString(),
                                                      movie: int.parse(
                                                          genre["movie"]
                                                              .toString()),
                                                      serie: int.parse(
                                                          genre["serie"]
                                                              .toString()))));
                                    },
                                    title: Text(
                                      genre["name"].toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox()
      ],
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: !_openCategories
          ? AppBar(
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
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SearchPage()));
                  },
                ),
              ],
            )
          : AppBar(
              toolbarHeight: 0,
            ),
      body: _isLoaded
          ? renderContents()
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
      bottomNavigationBar:
          _openCategories ? const SizedBox() : const Footer(current: 1),
    );
  }
}
