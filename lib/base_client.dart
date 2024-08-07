import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://localhost:8080/api/';

class BaseClient {
  var client = http.Client();

  Future<dynamic> get(String api, {Map<String, String> query = const {}}) async {
    // Append query parameters to the base URL
    var url = Uri.parse(baseUrl + api).replace(queryParameters: query);
    var headers = {
      'Authorization': '',
    };
    http.Response response = await client.get(url, headers: headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // logger
      throw Exception(response.body);
    }
  }

  Future<dynamic> post(String api, dynamic object) async {
    var url = Uri.parse(baseUrl + api);
    var payload = json.encode(object);
    var headers = {
      'Authorization': '',
      'Content-Type': 'application/json',
    };

    var response = await client.post(url, body: payload, headers: headers);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // logger
      throw Exception(response.body);
    }
  }

  Future<dynamic> put(String api, dynamic object) async {
    var url = Uri.parse(baseUrl + api);
    var payload = json.encode(object);
    var headers = {
      'Authorization': '',
      'Content-Type': 'application/json',
    };

    var response = await client.put(url, body: payload, headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      // logger
      throw Exception(response.body);
    }
  }

  Future<dynamic> delete(String api) async {
    var url = Uri.parse(baseUrl + api);
    var headers = {
      'Authorization': '',
    };

    var response = await client.delete(url, headers: headers);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      // logger
      throw Exception(response.body);
    }
  }
}

class CustomError implements Exception {
  final String message;

  CustomError(this.message);
}
