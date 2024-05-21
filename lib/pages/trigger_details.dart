import 'dart:async';
import 'dart:convert';

import 'package:app_movie/components/animated_cliprect.dart';
import 'package:app_movie/components/custom_snackbar.dart';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/feedback.dart';
import 'package:app_movie/pages/new_trigger_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<dynamic> triggers = [];
  List<String>? user;
  String? token;
  List<FeedbackCustom> feedbacks = [];
  bool _isLoaded = false;
  int limitSet = 2;
  String triggerSet = "0";
  final feedbackController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingFeedbacks = false;
  bool _isLoadingVotes = false;
  bool _isLoadingFavs = false;
  bool _isLoadingComment = false;
  bool _isLoadingMore = false;
  bool _isLoadingTriggers = false;
  bool _isSearching = false;
  String? currentFeedbackText;
  List<dynamic> favorites = [];
  List<String> openTriggers = [];
  String _indexLike = "-1";
  bool _openMoreTriggers = false;
  final searchText = TextEditingController();
  FirebaseFirestore db = FirebaseFirestore.instance;

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

  fetchFavoritesTriggers() async {
    var tf = await db
        .collection("triggers_favorites")
        .where("idUser", isEqualTo: user![Config.id])
        .get();

    if (tf.docs.isNotEmpty) {
      setState(() {
        favorites = tf.docs.map((v) => v.get("idTrigger") as String).toList();
      });
    } else {
      setState(() {
        favorites = [];
      });
    }
    setState(() {
      _isLoadingFavs = false;
    });
  }

  removeFavoriteTrigger(trigger) async {
    setState(() {
      _isLoadingFavs = true;
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
    Timer(
        const Duration(milliseconds: 200),
        () => CustomSnackBar.show(
            context, 'Removido dos favoritos com sucesso.'));
  }

  addFavoriteTrigger(trigger) async {
    setState(() {
      _isLoadingFavs = true;
    });
    var body = {'idUser': user![Config.id], 'idTrigger': trigger};
    db.collection("triggers_favorites").add(body).then((value) {
      Timer(
          const Duration(milliseconds: 200),
          () => CustomSnackBar.show(
              context, 'Adicionado aos favoritos com sucesso.'));
      fetchFavoritesTriggers();
    });
  }

  getData() async {
    // setState(() {
    //   _isLoaded = false;
    //   openTriggers = [];
    //   feedbacks = [];
    // });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      user = prefs.getStringList("user");
    });
    await fetchTriggers();
    await fetchFavoritesTriggers();
    await fetchFeedbacks(limitSet, triggerSet);

    setState(() {
      _isLoaded = true;
    });
  }

  vote(trigger, vote) async {
    setState(() {
      _isLoadingVotes = true;
    });
    var removeVote = false;
    var currentVote = await db
        .collection("triggers_content")
        .where("trigger", isEqualTo: trigger)
        .where("content", isEqualTo: widget.content)
        .where("user", isEqualTo: user![Config.id])
        .where("origin", isEqualTo: widget.origin)
        .get();
    if (currentVote.docs.isNotEmpty) {
      if (currentVote.docs.first.get("exists") == vote) removeVote = true;
      currentVote.docs.first.reference.delete();
    }

    if (!removeVote) {
      db.collection("triggers_content").add({
        "trigger": trigger,
        "content": widget.content,
        "user": user![Config.id],
        "origin": widget.origin,
        "exists": vote
      }).then((value) {
        showInSnackBar('Voto computado com sucesso.');
      });
    } else {
      showInSnackBar('Voto retirado com sucesso');
    }

    fetchTriggers();
  }

  fetchTriggers() async {
    var all = await db.collection("triggers").get();
    List<dynamic> result = [];
    if (all.docs.isNotEmpty) {
      await Future.forEach(all.docs, (element) async {
        var exists = {"total": 0, "voted": false};
        var notExists = {"total": 0, "voted": false};
        var query = await db
            .collection("triggers_content")
            .where("trigger", isEqualTo: element.id)
            .where("content", isEqualTo: widget.content)
            .where("origin", isEqualTo: widget.origin)
            .get();

        if (query.docs.isNotEmpty) {
          var sumVotesExist = 0;
          var sumVotesNotExist = 0;
          var existVoted = false;
          var notExistVoted = false;
          query.docs.forEach((e) {
            if (e.get("exists")) {
              sumVotesExist++;
              if (e.get("user") == user![Config.id]) {
                existVoted = true;
              }
            } else {
              sumVotesNotExist++;
              if (e.get("user") == user![Config.id]) {
                notExistVoted = true;
              }
            }
          });
          exists = {"voted": existVoted, "total": sumVotesExist};
          notExists = {"voted": notExistVoted, "total": sumVotesNotExist};
        }
        var data = {
          "id": element.id,
          "name": element.get("name"),
          "description": element.get("description"),
          "exists": exists,
          "notExists": notExists
        };

        result.add(data);
      });
      result
          .sort((a, b) => b["exists"]["total"].compareTo(a["exists"]["total"]));
    }
    setState(() {
      triggers = result;
      _isLoadingVotes = false;
      _isLoadingTriggers = false;
    });
  }

  fetchFeedbacks(limit, trigger) async {
    setState(() {
      _isLoadingFeedbacks = true;
    });
    var feedbacksDb = await db
        .collection("feedbacks")
        .where("origin", isEqualTo: widget.origin)
        .where("content", isEqualTo: widget.content)
        .get();
    if (feedbacksDb.docs.isNotEmpty) {
      List<FeedbackCustom> result = [];
      Future.forEach(feedbacksDb.docs, (x) async {
        var likedDb = await db
            .collection("feedbacks_likes")
            .where("feedback", isEqualTo: x.id)
            .where("user", isEqualTo: user![Config.id])
            .get();

        var liked = likedDb.docs.length > 0;

        var likesDb = await db
            .collection("feedbacks_likes")
            .where("feedback", isEqualTo: x.id)
            .get();
        var likes = 0;

        if (likesDb.docs.isNotEmpty) {
          likes = likesDb.docs.length;
        }

        var userDb = await db
            .collection("users")
            .where("email", isEqualTo: x.get("user"))
            .get();

        var data = {
          "id": x.id,
          "msg": x.get("msg"),
          "trigger": x.get("trigger"),
          "approved": x.get("approved"),
          "origin": widget.origin,
          "content": widget.content,
          "user": x.get("user"),
          "likes": likes,
          "liked": liked,
          "image": userDb.docs.first.get("image"),
          "username": userDb.docs.first.get("username")
        };

        result.add(FeedbackCustom.fromJson(data));
      });
      setState(() {
        feedbacks = result;
        _isLoading = false;
        triggerSet = trigger.toString();
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

  postFeedback(trigger) async {
    setState(() {
      _isLoadingComment = true;
    });

    if (feedbackController.text.isNotEmpty) {
      var body = {
        "trigger": trigger,
        "content": widget.content,
        "user": user![Config.id],
        "msg": feedbackController.text,
        "approved": true,
        "origin": widget.origin
      };
      db.collection("feedbacks").add(body).then((value) async {
        setState(() {
          feedbackController.text = '';
          _isLoadingComment = false;
          feedbacks = [];
          openTriggers = [];
        });
        showInSnackBar('Obrigado pelo seu comentário!');

        await fetchFeedbacks(limitSet, triggerSet);
      });
    } else {
      setState(() {
        _isLoadingComment = false;
      });
      showInSnackBar('Por favor preencher algum comentário');
    }
  }

  like(feedback) async {
    setState(() {
      _isLoading = true;
    });
    var data = {"user": user![Config.id], "feedback": feedback};
    await db.collection("feedbacks_likes").add(data);

    fetchFeedbacks(limitSet, triggerSet);
  }

  deslike(feedback) async {
    setState(() {
      _isLoading = true;
    });

    var like = await db
        .collection("feedbacks_likes")
        .where("feedback", isEqualTo: feedback)
        .where("user", isEqualTo: user![Config.id])
        .get();
    if (like.docs.first.exists) {
      await like.docs.first.reference.delete();
    }

    fetchFeedbacks(limitSet, triggerSet);
  }

  removeFeedback(id) async {
    var likes = await db
        .collection("feedbacks_likes")
        .where("feedback", isEqualTo: id)
        .get();
    if (likes.docs.first.exists) {
      await likes.docs.first.reference.delete();
    }
    await db.collection("feedbacks").doc(id).delete();

    showInSnackBar('Comentário removido com sucesso.');
    fetchFeedbacks(limitSet, triggerSet);
  }

  renderFeedbacks(index) {
    return AnimatedClipRect(
      open: openTriggers.contains(triggers[index]["id"]),
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
                currentFeedbackText = triggers[index]["id"];
              });
            },
            style: const TextStyle(color: Config.textColor),
            controller: currentFeedbackText == triggers[index]["id"]
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
                    postFeedback(triggers[index]["id"]);
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
                return feedbacks[fbIndex].trigger == triggers[index]["id"]
                    ? Card(
                        color: feedbacks[fbIndex].approved
                            ? Config.panelColor2
                            : Colors.red[200],
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
                                                  (feedbacks[fbIndex].user)
                                                      .toString(),
                                          child: TextButton(
                                            child: Icon(
                                              Icons.delete_outline_sharp,
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              removeFeedback(feedbacks[index]);
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
                                                  feedbacks[fbIndex].liked
                                                      ? deslike(
                                                          feedbacks[fbIndex].id)
                                                      : like(feedbacks[fbIndex]
                                                          .id);
                                                },
                                                child: feedbacks[fbIndex].liked
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

                if (triggerSet != triggers[index]["id"]) {
                  fetchFeedbacks(limitSet, triggers[index]["id"]);
                } else {
                  fetchFeedbacks(limitSet, "0");
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
                          triggerSet != triggers[index]["id"]
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
                                if (openTriggers
                                    .contains(triggers[index]["id"])) {
                                  openTriggers.remove(triggers[index]["id"]);
                                } else {
                                  openTriggers.add(triggers[index]["id"]);
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
                                            Config.primaryColor
                                          ],
                                        )),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: 16,
                                              bottom: 2,
                                              top: 2,
                                              right: 2),
                                          child: Text(
                                            utf8.decode(latin1.encode(
                                                triggers[index]["name"])),
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
                                                          triggers[index]["id"])
                                                      ? removeFavoriteTrigger(
                                                          triggers[index]["id"])
                                                      : addFavoriteTrigger(
                                                          triggers[index]
                                                              ["id"]);
                                                },
                                                child: SizedBox(
                                                  height: 30,
                                                  width: 30,
                                                  child: Icon(
                                                    favorites.contains(
                                                            triggers[index]
                                                                ["id"])
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
                                              vote(triggers[index]["id"], true);
                                            },
                                            child: Icon(
                                              Icons.check,
                                              color: triggers[index]["exists"]
                                                      ["voted"]
                                                  ? Colors.green
                                                  : Config.disabledColor
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                  Text(triggers[index]["exists"]["total"]
                                      .toString())
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
                                            vote(triggers[index]["id"], false);
                                          },
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Icon(
                                              Icons.close,
                                              color: triggers[index]
                                                      ["notExists"]["voted"]
                                                  ? Colors.red[900]
                                                  : Config.disabledColor
                                                      .withOpacity(0.5),
                                            ),
                                          ),
                                        ),
                                  Text(triggers[index]["notExists"]["total"]
                                      .toString())
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
            color: Colors.white,
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
                    cursorColor: Colors.white,
                    controller: searchText,
                    onChanged: fetchSearch,
                    decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          size: 16,
                          color: Colors.white,
                        ),
                        contentPadding:
                            const EdgeInsets.fromLTRB(16, 13, 16, 14),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: Color.fromARGB(180, 255, 255, 255)),
                        hintText: 'Pesquisar por Gatilhos...'),
                  ),
                ),
              )
            : Text(
                "Gatilhos de ${widget.title.length > 32 ? (widget.title.substring(0, 32) + "...") : widget.title}",
                style: TextStyle(
                    fontSize: widget.title.length > 29 ? 12 : 14,
                    color: Colors.white),
              ),
        actions: [
          // !_isSearching
          //     ? IconButton(
          //         onPressed: () {
          //           getData();
          //         },
          //         icon: Icon(
          //           Icons.replay_outlined,
          //           color: Colors.white,
          //         ))
          //     : const SizedBox(),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
              });
            },
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
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
