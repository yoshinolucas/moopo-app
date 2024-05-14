import 'dart:async';
import 'dart:convert';

import 'package:app_movie/pages/content_list.dart';
import 'package:app_movie/pages/search.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/content.dart';
import 'package:app_movie/pages/content_page.dart';
import 'package:app_movie/pages/footer.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _indexMovie = -1;
  int _indexAnime = -1;
  int _indexSerie = -1;

  PageController _pageController = PageController(initialPage: 0);
  List<String>? user;
  String? token;
  int _currentPage = 0;
  List<Content>? animes = [];
  List<Content>? banners = [];
  List<Content>? movies = [];
  List<Content>? series = [];
  List<int>? favoritesMovies = [];
  List<int>? favoritesSeries = [];
  List<int>? favoritesAnimes = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  final _widthCard = 129.0;
  final _heigthCard = 200.0;
  final _sizeFavIcon = 20.0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    getData();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
    _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (_currentPage == 4) {
        setState(() {
          _currentPage = 0;
        });
      } else {
        setState(() {
          _currentPage++;
        });
      }

      _pageController.animateToPage(
        _currentPage,
        duration: Duration(milliseconds: 350),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer!.cancel();
    _pageController.dispose();
    super.dispose();
  }

  getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
    });
    await fetchMovies();
    movies = await ContentRepository.fetchContents(1, Config.movie);
    series = await ContentRepository.fetchContents(1, Config.serie);
    animes = await ContentRepository.fetchContents(1, Config.anime);
    await fetchFavorites();
    setState(() {
      _isLoaded = true;
    });
  }

  fetchMovies() async {
    var response = await http.get(
        Uri.parse("${Config.urlTmdb}/3/movie/popular?language=pt-BR"),
        headers: {
          "Accept": "application/json",
          "Authorization": Config.apiKey
        });
    if (response.statusCode == 200) {
      setState(() {
        for (var i = 0; i < 5; i++) {
          banners!
              .add(Content.fromJson(json.decode(response.body)['results'][i]));
        }
      });
    } else {
      throw Exception('Failed to load movies');
    }
  }

  fetchFavorites() async {
    setState(() {
      favoritesMovies = [];
      favoritesSeries = [];
      favoritesAnimes = [];
    });

    var db = FirebaseFirestore.instance;
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
    var db = FirebaseFirestore.instance;
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
    var db = FirebaseFirestore.instance;
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

  reset() {
    setState(() {
      _indexAnime = -1;
      _indexSerie = -1;
      _indexMovie = -1;
    });
  }

  renderSeries() {
    return SizedBox(
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
                        _isLoading && _indexSerie == index
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
                                  reset();
                                  setState(() {
                                    _indexSerie = index;
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
              ]),
            );
          }),
    );
  }

  renderMovies() {
    return SizedBox(
      height: _heigthCard + 72,
      width: double.infinity,
      child: ListView.builder(
          physics: const ClampingScrollPhysics(),
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: movies!.length,
          itemBuilder: (context, index) {
            return (movies![index].posterPath != "")
                ? Padding(
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
                              _isLoading && _indexMovie == index
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
                                        reset();
                                        setState(() {
                                          _indexMovie = index;
                                        });
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
                  )
                : const SizedBox();
          }),
    );
  }

  renderAnimes() {
    return SizedBox(
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
                        _isLoading && _indexAnime == index
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
                                  reset();
                                  setState(() {
                                    _indexAnime = index;
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
              ]),
            );
          }),
    );
  }

  List<Widget> _buildIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < banners!.length; i++) {
      indicators.add(
        Container(
          width: 6.0,
          height: 6.0,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == i
                ? Config.primaryColor
                : Colors.grey, // Cor do indicador ativo e inativo
          ),
        ),
      );
    }
    return indicators;
  }

  renderBanners() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                color: Colors.black,
                height: 211,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ContentPage(
                                    movie: banners![index],
                                    origin: Config.movie)));
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.network(
                            banners![index].backdropPath,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: SizedBox(
                                width: 100,
                                child: Text(
                                  banners![index].title,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 11.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildIndicators(),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Config.primaryColor,
            automaticallyImplyLeading: false,
            title: Image.asset(Config.shortLogoWhite),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SearchPage()));
                },
              )
            ],
          ),
          body: _isLoaded
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 29,
                      ),
                      renderBanners(),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
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
                      ),
                      renderMovies(),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
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
                      ),
                      renderAnimes(),
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 8),
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
                      renderSeries(),
                    ],
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
          bottomNavigationBar: const Footer()),
    );
  }
}
