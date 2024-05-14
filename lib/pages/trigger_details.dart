import 'dart:async';
import 'dart:convert';

import 'package:app_movie/components/animated_cliprect.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/feedback.dart';
import 'package:app_movie/entities/trigger.dart';
import 'package:app_movie/pages/new_trigger_content.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TriggerDetails extends StatefulWidget {
  final int origin;
  final int content;
  final String title;
  const TriggerDetails(
      {super.key, this.content = 0, this.title = '', required this.origin});

  @override
  State<TriggerDetails> createState() => _TriggerDetailsState();
}

class _TriggerDetailsState extends State<TriggerDetails> {
  List<Trigger> triggers = [];
  List<String>? user;
  String? token;
  List<Map<String, dynamic>> exists = [];
  List<Map<String, dynamic>> notExists = [];
  List<FeedbackCustom> feedbacks = [];
  bool _isLoaded = false;
  int limitSet = 2;
  int triggerSet = 0;
  final feedbackController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingFeedbacks = false;
  bool _isLoadingVotes = false;
  bool _isLoadingFavs = false;
  bool _isLoadingComment = false;
  bool _isLoadingMore = false;
  bool _isLoadingTriggers = false;
  bool _isSearching = false;
  int? currentFeedbackText;
  List<dynamic> favorites = [];
  List<int> openTriggers = [];
  int _indexLike = -1;
  bool _openMoreTriggers = false;
  final searchText = TextEditingController();
  @override
  void initState() {
    super.initState();
    getData();
  }

  addFavorite(trigger) async {
    setState(() {
      _isLoadingFavs = true;
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
      fetchFavorites();
      showInSnackBar('Adicionado aos favoritos com sucesso.');
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

  fetchFavorites() async {
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
        favorites = json.decode(response.body).cast<int>();
        _isLoadingFavs = false;
      });
    } else {
      throw Exception('Failed to load Favorites');
    }
  }

  removeFavorite(trigger) async {
    setState(() {
      _isLoadingFavs = true;
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
    await fetchTriggers();
    await fetchFavorites();
    await fetchFeedbacks(limitSet, triggerSet);

    setState(() {
      _isLoaded = true;
    });
  }

  vote(trigger, vote) async {
    setState(() {
      _isLoadingVotes = true;
    });

    var response = await http.post(
        Uri.parse(
            "${Config.api}/triggers/vote?id=$trigger&content=${widget.content}&user=${user![Config.id]}&vote=$vote&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchTriggers();
      showInSnackBar('Voto computado com sucesso.');
    }
  }

  fetchTriggers() async {
    int all = _openMoreTriggers ? 1 : 0;
    var response = await http.get(
        Uri.parse(
            "${Config.api}/triggers/content?id=${widget.content}&user=${user![Config.id]}&origin=${widget.origin}&all=$all&search=${searchText.text}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      setState(() {
        exists = [];
        notExists = [];
        for (var item in json.decode(response.body)) {
          exists.add({"total": item['exists'], "voted": item['votedExist']});
          notExists.add(
              {"total": item['notExists'], "voted": item['votedNotExist']});
        }
        triggers = List<Trigger>.from(json
            .decode(response.body)
            .map((x) => Trigger.fromJson(x['trigger'])));
        _isLoadingVotes = false;
        _isLoadingTriggers = false;
      });
    }
  }

  fetchFeedbacks(limit, trigger) async {
    setState(() {
      _isLoadingFeedbacks = true;
    });
    var response = await http.get(
        Uri.parse(
            "${Config.api}/feedbacks/content?id=${widget.content}&user=${user![Config.id]}&limit=$limit&trigger=$trigger&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      if (json.decode(response.body).isNotEmpty) {
        setState(() {
          feedbacks = List<FeedbackCustom>.from(json
              .decode(response.body)
              .map((x) => FeedbackCustom.fromJson(x)));
          _isLoading = false;
          triggerSet = trigger;
          _isLoadingFeedbacks = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingFeedbacks = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  postFeedback(trigger) async {
    setState(() {
      _isLoadingComment = true;
    });

    if (feedbackController.text.isNotEmpty) {
      var body = json.encode({
        "id_trigger": trigger,
        "id_content": widget.content,
        "id_user": user![Config.id],
        "msg": feedbackController.text,
        "approved": 1,
        "origin": widget.origin
      });
      var response = await http
          .post(Uri.parse("${Config.api}/feedbacks/add"), body: body, headers: {
        "Accept": "application/json",
        "content-type": "application/json",
        "Authorization": token!
      });
      if (response.statusCode == 200) {
        setState(() {
          feedbackController.text = '';
          _isLoadingComment = false;
        });
        showInSnackBar('Obrigado pelo seu comentário!');
        fetchFeedbacks(limitSet, triggerSet);
      }
    } else {
      setState(() {
        _isLoadingComment = false;
      });
    }
  }

  like(feedback) async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.post(
        Uri.parse(
            "${Config.api}/feedbacks/like?id=$feedback&user=${user![Config.id]}&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchFeedbacks(limitSet, triggerSet);
    }
  }

  deslike(feedback) async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.delete(
        Uri.parse(
            "${Config.api}/feedbacks/deslike?id=$feedback&user=${user![Config.id]}&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      fetchFeedbacks(limitSet, triggerSet);
    }
  }

  removeFeedback(id) async {
    var response = await http.delete(
        Uri.parse(
            "${Config.api}/feedbacks/delete?id=$id&origin=${widget.origin}"),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": token!
        });
    if (response.statusCode == 200) {
      showInSnackBar('Comentário removido com sucesso.');
      fetchFeedbacks(limitSet, triggerSet);
    }
  }

  renderFeedbacks(index) {
    return AnimatedClipRect(
      open: openTriggers.contains(triggers[index].id),
      horizontalAnimation: false,
      verticalAnimation: true,
      alignment: Alignment.center,
      duration: const Duration(milliseconds: 400),
      curve: Curves.linear,
      reverseCurve: Curves.linear,
      child: Column(
        children: [
          const SizedBox(
            height: 8,
          ),
          TextField(
            onTap: () {
              setState(() {
                currentFeedbackText = triggers[index].id;
              });
            },
            style: const TextStyle(color: Config.textColor),
            controller: currentFeedbackText == triggers[index].id
                ? feedbackController
                : null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'Adicione um comentário',
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: () {
                    postFeedback(triggers[index].id);
                  },
                  style: const ButtonStyle(
                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(32)))),
                  ),
                  child: Container(
                      alignment: Alignment.center,
                      height: 32,
                      padding: const EdgeInsets.all(6),
                      child: _isLoadingComment
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('Comentar',
                              style: TextStyle(fontSize: 14))),
                ),
              )),
          const SizedBox(
            height: 8,
          ),
          ListView.builder(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              itemCount: feedbacks.length,
              itemBuilder: (context, fbIndex) {
                return feedbacks[fbIndex].idTrigger == triggers[index].id
                    ? Card(
                        color: feedbacks[fbIndex].approved == 2
                            ? Colors.red[200]
                            : Config.panelColor2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(200),
                                child: Container(
                                    alignment: Alignment.center,
                                    color: Config.panelColor2,
                                    height: 46,
                                    width: 46,
                                    child: feedbacks[fbIndex].image == ''
                                        ? const Icon(Icons.person)
                                        : Image.network(
                                            feedbacks[fbIndex].image)),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "@${feedbacks[fbIndex].username}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800),
                                        ),
                                        Visibility(
                                          visible: user![Config.role] == '1' ||
                                              user![Config.id].toString() ==
                                                  (feedbacks[fbIndex].idUser)
                                                      .toString(),
                                          child: TextButton(
                                            child: Icon(
                                              Icons.delete_outline_sharp,
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              removeFeedback(
                                                  feedbacks[index].id);
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 14,
                                    ),
                                    Text(utf8.decode(
                                        latin1.encode(feedbacks[fbIndex].msg))),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        _isLoading &&
                                                _indexLike ==
                                                    feedbacks[fbIndex].id
                                            ? SizedBox(
                                                height: 36,
                                                width: 36,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Config.primaryColor,
                                                  ),
                                                ))
                                            : InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _indexLike =
                                                        feedbacks[fbIndex].id;
                                                  });
                                                  feedbacks[fbIndex].liked == 1
                                                      ? deslike(
                                                          feedbacks[fbIndex].id)
                                                      : like(feedbacks[fbIndex]
                                                          .id);
                                                },
                                                child: feedbacks[fbIndex]
                                                            .liked ==
                                                        1
                                                    ? SizedBox(
                                                        height: 36,
                                                        width: 36,
                                                        child: Icon(
                                                          Icons.thumb_up_alt,
                                                          color: Config
                                                              .primaryColor,
                                                        ),
                                                      )
                                                    : SizedBox(
                                                        height: 36,
                                                        width: 36,
                                                        child: const Icon(Icons
                                                            .thumb_up_alt_outlined),
                                                      ),
                                              ),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        Text(
                                          feedbacks[fbIndex].likes.toString(),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ))
                    : const SizedBox();
              }),
          TextButton(
              onPressed: () {
                setState(() {
                  _isLoadingMore = true;
                });

                if (triggerSet != triggers[index].id) {
                  fetchFeedbacks(limitSet, triggers[index].id);
                } else {
                  fetchFeedbacks(limitSet, 0);
                }
              },
              child: _isLoadingFeedbacks && _isLoadingMore
                  ? SizedBox(
                      height: 30,
                      width: 30,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: CircularProgressIndicator(
                          color: Config.primaryColor,
                        ),
                      ))
                  : Visibility(
                      visible: feedbacks.isNotEmpty,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          triggerSet != triggers[index].id
                              ? "mais comentários"
                              : "esconder comentários",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ))
        ],
      ),
    );
  }

  renderTriggers() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: triggers.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Está presente?",
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 7,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (openTriggers.contains(triggers[index].id)) {
                                  openTriggers.remove(triggers[index].id);
                                } else {
                                  openTriggers.add(triggers[index].id);
                                }
                              });
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    Container(
                                        height: 86,
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
                                          padding: const EdgeInsets.only(
                                              left: 16,
                                              bottom: 2,
                                              top: 2,
                                              right: 2),
                                          child: Text(
                                            utf8.decode(latin1
                                                .encode(triggers[index].name)),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18),
                                          ),
                                        )),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(Icons.comment,
                                            color: Colors.white),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        _isLoadingFavs
                                            ? const SizedBox(
                                                height: 30,
                                                width: 30,
                                                child: Padding(
                                                  padding: EdgeInsets.all(6.0),
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Colors.white,
                                                  ),
                                                ))
                                            : InkWell(
                                                onTap: () {
                                                  favorites.contains(
                                                          triggers[index].id)
                                                      ? removeFavorite(
                                                          triggers[index].id)
                                                      : addFavorite(
                                                          triggers[index].id);
                                                },
                                                child: SizedBox(
                                                  height: 30,
                                                  width: 30,
                                                  child: Icon(
                                                    favorites.contains(
                                                            triggers[index].id)
                                                        ? Icons.star
                                                        : Icons
                                                            .star_border_outlined,
                                                    color: Colors.white,
                                                  ),
                                                ))
                                      ],
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                children: [
                                  _isLoadingVotes
                                      ? SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              color: Config.primaryColor,
                                            ),
                                          ))
                                      : SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: InkWell(
                                            onTap: () {
                                              vote(triggers[index].id, 1);
                                            },
                                            child: Icon(
                                              Icons.check,
                                              color: exists[index]["voted"] == 1
                                                  ? Colors.green
                                                  : Config.disabledColor
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                  Text(exists[index]["total"].toString())
                                ],
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Column(
                                children: [
                                  _isLoadingVotes
                                      ? SizedBox(
                                          height: 36,
                                          width: 36,
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(
                                              color: Config.primaryColor,
                                            ),
                                          ))
                                      : InkWell(
                                          onTap: () {
                                            vote(triggers[index].id, 0);
                                          },
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Icon(
                                              Icons.close,
                                              color:
                                                  notExists[index]["voted"] == 1
                                                      ? Colors.red[900]
                                                      : Config.disabledColor
                                                          .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                  Text(notExists[index]["total"].toString())
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    renderFeedbacks(index),
                    const SizedBox(
                      height: 8,
                    )
                  ],
                );
              }),
        ),
        searchText.text.isNotEmpty
            ? const SizedBox()
            : Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                  child: _isLoadingTriggers
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Config.primaryColor,
                          ),
                        )
                      : InkWell(
                          onTap: () {
                            setState(() {
                              _isLoadingTriggers = true;
                              _openMoreTriggers = !_openMoreTriggers;
                            });
                            fetchTriggers();
                          },
                          child: Text(
                            _openMoreTriggers
                                ? "esconder gatilhos"
                                : "mostrar mais gatilhos",
                            style: TextStyle(color: Config.primaryColor),
                          ),
                        ),
                ),
              )
      ],
    );
  }

  Timer? _debounceTimer;
  void fetchSearch(String txt) async {
    if (_debounceTimer != null) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      fetchTriggers();
    });
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
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: _isSearching
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: searchText,
                    onChanged: fetchSearch,
                    decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                        ),
                        contentPadding:
                            const EdgeInsets.fromLTRB(16, 13, 16, 14),
                        border: InputBorder.none,
                        hintText: 'Pesquisar por Gatilhos...'),
                  ),
                ),
              )
            : Text(
                "Gatilhos de ${widget.title.length > 32 ? (widget.title.substring(0, 32) + "...") : widget.title}",
                style: TextStyle(fontSize: widget.title.length > 29 ? 12 : 14),
              ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
          ),
          user![Config.role] == '1'
              ? IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NewTriggerContent(
                                content: widget.content,
                                origin: widget.origin)));
                  },
                  icon: const Icon(Icons.add))
              : const SizedBox()
        ],
      ),
      body: _isLoaded
          ? renderTriggers()
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
