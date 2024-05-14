class FeedbackCustom {
  final int id;
  final int idContent;
  final int idUser;
  final String username;
  final String msg;
  final int likes;
  final int liked;
  final int approved;
  final int idTrigger;
  final int origin;
  final String image;

  const FeedbackCustom(
      {required this.id,
      required this.idContent,
      required this.idUser,
      required this.username,
      required this.msg,
      required this.likes,
      required this.liked,
      required this.approved,
      required this.idTrigger,
      required this.origin,
      required this.image});

  factory FeedbackCustom.fromJson(Map<String, dynamic> json) => FeedbackCustom(
      id: json['id'],
      idContent: json['id_content'],
      idUser: json['id_user'],
      msg: json['msg'],
      likes: json['likes'],
      liked: json['liked'],
      username: json['username'],
      approved: json['approved'],
      idTrigger: json['id_trigger'],
      origin: json["origin"],
      image: json['image'] ?? '');

  Map<String, dynamic> toJson() => {
        "id": id,
        "id_content": idContent,
        "id_user": idUser,
        "msg": msg,
        "username": username,
        "likes": likes,
        "liked": liked,
        "approved": approved,
        "id_trigger": idTrigger,
        "origin": origin,
        "image": image
      };
}
