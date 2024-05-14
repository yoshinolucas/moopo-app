import 'dart:convert';
import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/genre.dart';
import 'package:http/http.dart' as http;

class GenreRepository {
  static Future<List<Genre>> fetch(type) async {
    var response = await http.get(
        Uri.parse("${Config.urlTmdb}/3/genre/$type/list?language=pt-BR"),
        headers: {'Authorization': Config.apiKey});
    if (response.statusCode == 200) {
      return List<Genre>.from(
          json.decode(response.body)['genres'].map((x) => Genre.fromJson(x)));
    } else {
      throw Exception('Failed to load Genres');
    }
  }
}
