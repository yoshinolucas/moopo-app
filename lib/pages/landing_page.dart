import 'dart:async';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/pages/login_page.dart';
import 'package:app_movie/pages/new_user.dart';
import 'package:app_movie/repositories/content_repository.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Color transparentColor = Colors.transparent;
  Color primaryColor = const Color.fromARGB(255, 255, 212, 217);
  Color secondaryColor = const Color.fromARGB(255, 244, 167, 176);
  bool isHover = false;
  int _hoveredIndex = -1;
  bool _isOpen = false;

  List<dynamic> triggers = [
    {
      "id": 1,
      "name": "Violência?",
    },
    {
      "id": 2,
      "name": "Um Cachorro Morre?",
    },
    {"id": 3, "name": "Tem Drogas Ilícitas?"},
    {"id": 4, "name": "Tem Cirurgia?"},
    {"id": 5, "name": "Decepção Amorosa?"},
    {"id": 6, "name": "Tem Sangue?"},
  ];
  List<dynamic> violencias = [];
  List<dynamic> dogs = [];
  List<dynamic> blood = [];
  List<dynamic> surgery = [];
  List<dynamic> love = [];
  List<dynamic> drugs = [];
  dynamic trigger = {};
  bool _isLoaded = false;
  renderTriggers() {
    return GridView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).size.shortestSide < 650 ? 3 : 6,
          childAspectRatio: (1 / .4),
        ),
        itemCount: triggers.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isOpen = true;
                    trigger = triggers[index];
                  });
                },
                onHover: (value) => {
                  setState(() {
                    isHover = value;
                    _hoveredIndex = index;
                  })
                },
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: primaryColor,
                      ),
                      color: _hoveredIndex == index && isHover ||
                              trigger == triggers[index]
                          ? primaryColor
                          : transparentColor),
                  alignment: Alignment.center,
                  child: Text(
                    triggers[index]["name"],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _hoveredIndex == index && isHover ||
                                trigger == triggers[index]
                            ? const Color.fromARGB(255, 33, 12, 16)
                            : primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    getData();
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _isLoaded = true;
      });
    });
  }

  getData() async {
    dynamic v1 = await ContentRepository.fetchContentById(813, Config.anime);
    dynamic v2 = await ContentRepository.fetchContentById(185, Config.movie);
    dynamic v3 = await ContentRepository.fetchContentById(185, Config.movie);
    dynamic v4 = await ContentRepository.fetchContentById(185, Config.movie);
    dynamic v5 = await ContentRepository.fetchContentById(414906, Config.movie);
    dynamic v6 = await ContentRepository.fetchContentById(1399, Config.movie);
    List<dynamic> v = [v1, v2, v3, v4, v5, v6];
    dynamic d1 = await ContentRepository.fetchContentById(5114, Config.movie);
    dynamic d2 = await ContentRepository.fetchContentById(245891, Config.movie);
    dynamic d3 = await ContentRepository.fetchContentById(245891, Config.movie);
    dynamic d4 = await ContentRepository.fetchContentById(14719, Config.movie);
    dynamic d5 = await ContentRepository.fetchContentById(1359, Config.movie);
    dynamic d6 = await ContentRepository.fetchContentById(14306, Config.movie);
    List<dynamic> d = [d1, d2, d3, d4, d5, d6];
    dynamic s1 = await ContentRepository.fetchContentById(22199, Config.movie);
    dynamic s2 = await ContentRepository.fetchContentById(103, Config.movie);
    dynamic s3 = await ContentRepository.fetchContentById(40008, Config.movie);
    dynamic s4 = await ContentRepository.fetchContentById(31240, Config.movie);
    dynamic s5 = await ContentRepository.fetchContentById(475557, Config.movie);
    dynamic s6 = await ContentRepository.fetchContentById(1405, Config.movie);
    List<dynamic> s = [s1, s2, s3, s4, s5, s6];
    dynamic c1 = await ContentRepository.fetchContentById(93405, Config.movie);
    dynamic c2 = await ContentRepository.fetchContentById(306819, Config.movie);
    dynamic c3 = await ContentRepository.fetchContentById(1408, Config.movie);
    dynamic c4 = await ContentRepository.fetchContentById(1416, Config.movie);
    dynamic c5 = await ContentRepository.fetchContentById(63311, Config.movie);
    dynamic c6 = await ContentRepository.fetchContentById(1405, Config.movie);
    List<dynamic> c = [c1, c2, c3, c4, c5, c6];
    dynamic a1 = await ContentRepository.fetchContentById(11757, Config.movie);
    dynamic a2 = await ContentRepository.fetchContentById(38, Config.movie);
    dynamic a3 = await ContentRepository.fetchContentById(78191, Config.movie);
    dynamic a4 = await ContentRepository.fetchContentById(19913, Config.movie);
    dynamic a5 = await ContentRepository.fetchContentById(152601, Config.movie);
    dynamic a6 = await ContentRepository.fetchContentById(289, Config.movie);
    List<dynamic> a = [a1, a2, a3, a4, a5, a6];
    dynamic i1 = await ContentRepository.fetchContentById(900, Config.movie);
    dynamic i2 = await ContentRepository.fetchContentById(641, Config.movie);
    dynamic i3 = await ContentRepository.fetchContentById(1396, Config.movie);
    dynamic i4 = await ContentRepository.fetchContentById(627, Config.movie);
    dynamic i5 = await ContentRepository.fetchContentById(35120, Config.movie);
    dynamic i6 = await ContentRepository.fetchContentById(7347, Config.movie);
    List<dynamic> i = [i1, i2, i3, i4, i5, i6];

    setState(() {
      violencias = v;
      dogs = d;
      surgery = c;
      blood = s;
      love = a;
      drugs = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 15, 12, 26),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 15, 12, 26),
          actions: [
            SizedBox(
              width: 90,
              child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: const Text(
                    "Entrar",
                    style: TextStyle(color: Colors.white),
                  )),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => NewUser()));
                  },
                  child: Container(
                    width: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: Colors.white)),
                    child: const Text("Criar Conta"),
                  )),
            )
          ],
        ),
        body: _isLoaded
            ? SingleChildScrollView(
                child: Padding(
                  padding: MediaQuery.of(context).size.width > 1100
                      ? const EdgeInsets.only(
                          left: 190, right: 190, bottom: 20, top: 90)
                      : const EdgeInsets.only(
                          left: 8, right: 8, bottom: 20, top: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Descubra cenas dos seus gatilhos em filmes, séries, animes e mais.",
                        style: TextStyle(fontSize: 32, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      renderTriggers(),
                      const SizedBox(
                        height: 16,
                      ),
                      _isOpen && _isLoaded
                          ? Container(
                              color: const Color.fromARGB(255, 22, 18, 38),
                              width: double.infinity,
                              height: 270,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListView.builder(
                                    physics: const ClampingScrollPhysics(),
                                    shrinkWrap: true,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: violencias.length,
                                    itemBuilder: (context, index) {
                                      return Card(
                                        color: const Color.fromARGB(
                                            255, 15, 12, 26),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Stack(
                                              alignment: Alignment.bottomLeft,
                                              children: [
                                                Image.network(
                                                    trigger["id"] == 1
                                                        ? violencias[index]
                                                            .posterPath
                                                        : trigger["id"] == 2
                                                            ? dogs[index]
                                                                .posterPath
                                                            : trigger["id"] == 3
                                                                ? drugs[index]
                                                                    .posterPath
                                                                : trigger["id"] ==
                                                                        4
                                                                    ? surgery[
                                                                            index]
                                                                        .posterPath
                                                                    : trigger["id"] ==
                                                                            5
                                                                        ? love[index]
                                                                            .posterPath
                                                                        : blood[index]
                                                                            .posterPath,
                                                    fit: BoxFit.cover,
                                                    height: 270,
                                                    width: 180,
                                                    gaplessPlayback: true),
                                                Container(
                                                  alignment:
                                                      Alignment.bottomLeft,
                                                  decoration:
                                                      const BoxDecoration(
                                                    gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: <Color>[
                                                          Colors.transparent,
                                                          Color.fromARGB(
                                                              197, 0, 0, 0),
                                                          Color.fromARGB(
                                                              197, 0, 0, 0),
                                                        ]),
                                                  ),
                                                  width: 180,
                                                  height: 90,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      trigger["id"] == 1
                                                          ? violencias[index]
                                                              .title
                                                          : trigger["id"] == 2
                                                              ? dogs[index]
                                                                  .title
                                                              : trigger["id"] ==
                                                                      3
                                                                  ? drugs[index]
                                                                      .title
                                                                  : trigger["id"] ==
                                                                          4
                                                                      ? surgery[
                                                                              index]
                                                                          .title
                                                                      : trigger["id"] ==
                                                                              5
                                                                          ? love[index]
                                                                              .title
                                                                          : blood[index]
                                                                              .title,
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14),
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      );
                                    }),
                              ),
                            )
                          : const SizedBox()
                    ],
                  ),
                ),
              )
            : Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Icon(
                  Icons.warning_sharp,
                  color: Config.primaryColor,
                  size: 64,
                ),
              ));
  }
}
