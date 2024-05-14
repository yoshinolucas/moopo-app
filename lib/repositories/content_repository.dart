import 'dart:convert';

import 'package:app_movie/config/config.dart';

import 'package:http/http.dart' as http;

import '../entities/content.dart';

class ContentRepository {
  static Future<List<Content>?> fetchContentsBySearch(search, type) async {
    String uri = '';
    if (type == Config.movie) {
      uri = "${Config.urlTmdb}/3/search/movie?query=$search&language=pt-BR";
    } else {
      uri = "${Config.urlTmdb}/3/search/tv?query=$search&language=pt-BR";
    }
    final response = await http
        .get(Uri.parse(uri), headers: {'Authorization': Config.apiKey});

    if (response.statusCode == 200) {
      List<Content>? result = List<Content>.from(json
          .decode(response.body)['results']
          .map((x) => Content.fromJson(x)));
      return result;
    } else {
      throw Exception('Failed to load Content');
    }
  }

  static Future<List<Content>?> fetchContents(page, type) async {
    String uri = '';
    if (type == Config.movie) {
      uri = "${Config.urlTmdb}/3/movie/popular?language=pt-BR&page=$page";
    } else if (type == Config.serie) {
      uri =
          "${Config.urlTmdb}/3/discover/tv?language=pt-BR&page=$page&sort_by=vote_count.desc&without_keywords=210024";
    } else {
      uri =
          "${Config.urlTmdb}/3/discover/tv?language=pt-BR&page=$page&sort_by=vote_count.desc&with_keywords=210024";
    }

    var response = await http
        .get(Uri.parse(uri), headers: {'Authorization': Config.apiKey});

    if (response.statusCode == 200) {
      return List<Content>.from(json
          .decode(response.body)['results']
          .map((x) => Content.fromJson(x)));
    } else {
      throw Exception('Failed to load Content');
    }
  }

  static Future<Content> fetchContentById(id, type) async {
    String uri = '';
    if (type == Config.movie) {
      uri = "${Config.urlTmdb}/3/movie/$id?language=pt-BR";
    } else {
      uri = "${Config.urlTmdb}/3/tv/$id?language=pt-BR";
    }
    var response = await http
        .get(Uri.parse(uri), headers: {'Authorization': Config.apiKey});
    if (response.statusCode == 200) {
      return Content.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load Content');
    }
  }

  static Future<List<dynamic>?> fetchMoviesProvidersById(movie) async {
    var response = await http.get(
        Uri.parse("${Config.urlTmdb}/3/movie/$movie/watch/providers"),
        headers: {'Authorization': Config.apiKey});
    if (response.statusCode == 200) {
      try {
        return json.decode(response.body)['results']['BR']['rent'];
      } catch (e) {
        return null;
      }
    } else {
      throw Exception('Failed to load Providers');
    }
  }

  static Future<List<Content>?> fetchContentsByGenre(genre, type) async {
    String uri = '';
    if (type == Config.serie) {
      uri =
          "${Config.urlTmdb}/3/discover/tv?with_genres=$genre&language=pt-BR&without_keywords=210024";
    } else if (type == Config.anime) {
      uri =
          "${Config.urlTmdb}/3/discover/tv?with_genres=$genre&language=pt-BR&with_keywords=210024";
    } else {
      uri =
          "${Config.urlTmdb}/3/discover/movie?with_genres=$genre&language=pt-BR";
    }

    var response = await http
        .get(Uri.parse(uri), headers: {'Authorization': Config.apiKey});
    if (response.statusCode == 200) {
      return List<Content>.from(json
          .decode(response.body)['results']
          .map((x) => Content.fromJson(x)));
    } else {
      throw Exception('Failed to load Contents');
    }
  }
}
