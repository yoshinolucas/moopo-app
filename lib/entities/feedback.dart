class FeedbackCustom {
  final String id;
  final int content;
  final String user;
  final String username;
  final String msg;
  final int likes;
  final bool liked;
  final bool approved;
  final String trigger;
  final int origin;
  final String image;

  const FeedbackCustom(
      {required this.id,
      required this.content,
      required this.user,
      required this.username,
      required this.msg,
      required this.likes,
      required this.liked,
      required this.approved,
      required this.trigger,
      required this.origin,
      required this.image});

  factory FeedbackCustom.fromJson(Map<String, dynamic> json) => FeedbackCustom(
      id: json['id'],
      content: json['content'],
      user: json['user'],
      msg: json['msg'],
      likes: json['likes'],
      liked: json['liked'],
      username: json['username'],
      approved: json['approved'],
      trigger: json['trigger'],
      origin: json["origin"],
      image: json['image'] ?? '');

  Map<String, dynamic> toJson() => {
        "id": id,
        "content": content,
        "user": user,
        "msg": msg,
        "username": username,
        "likes": likes,
        "liked": liked,
        "approved": approved,
        "trigger": trigger,
        "origin": origin,
        "image": image
      };
}
