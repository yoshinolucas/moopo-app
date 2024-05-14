class Content {
  final int id;
  final String title;
  final String overview;
  final String posterPath;
  final double voteAverage;
  final List<dynamic> genreIds;
  final String backdropPath;
  final String original_language;

  const Content(
      {required this.id,
      required this.title,
      required this.overview,
      required this.posterPath,
      required this.genreIds,
      required this.backdropPath,
      required this.voteAverage,
      required this.original_language});

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
        id: json['id'],
        overview: json['overview'] ?? '',
        title: json['name'] ?? json['title'],
        posterPath: json['poster_path'] == null
            ? ""
            : "https://image.tmdb.org/t/p/w500${json['poster_path']}",
        voteAverage: json['vote_average'].toDouble(),
        backdropPath: "https://image.tmdb.org/t/p/w500${json['backdrop_path']}",
        genreIds: json['genre_ids'] ?? [],
        original_language: json["original_language"]);
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "overview": overview,
        "poster_path": posterPath,
        "vote_average": voteAverage,
        "backdrop_path": backdropPath,
        "genre_ids": genreIds,
        "original_language": original_language
      };
}
