import 'dart:convert';

import 'package:app_movie/config/config.dart';
import 'package:app_movie/entities/trigger.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TriggerRepository {
  static Future<List<Trigger>?> getTriggersBySearch(
      String search, int limit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var response = await http.post(
        Uri.parse("${Config.api}/triggers/all?page=1&limit=$limit"),
        body: json.encode({"search": search, "order": "id"}),
        headers: {
          "Accept": "application/json",
          "content-type": "application/json",
          "Authorization": prefs.get("token").toString()
        });
    if (response.statusCode == 200) {
      List<Trigger>? result = List<Trigger>.from(
          json.decode(response.body).map((x) => Trigger.fromJson(x)));
      return result;
    } else {
      throw Exception('Failed to load Triggers');
    }
  }
}
