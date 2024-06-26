class Genre {
  final int id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) =>
      Genre(id: json['id'] ?? json['mal_id'], name: json['name']);

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}
