import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

const clientBaseUrl = 'https://jsonplaceholder.typicode.com/posts';

class ClientApi {
  static Future<List<Client>> readAll() async {
    final res = await http.get(Uri.parse('$clientBaseUrl?_limit=8'));
    if (res.statusCode != 200) throw Exception('Failed to load (${res.statusCode})');
    final List data = jsonDecode(res.body);
    return data.map((e) => Client.fromJson(e)).toList();
  }

  static Future<Client> create(String title, String body) async {
    final res = await http.post(Uri.parse(clientBaseUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'title': title, 'body': body, 'userId': 1}));
    if (res.statusCode != 201) throw Exception('Failed to create (${res.statusCode})');
    final json = jsonDecode(res.body);
    return Client(id: DateTime.now().millisecondsSinceEpoch, title: json['title'], body: json['body']);
  }

  static Future<void> update(int id, String title, String body) async {
    final res = await http.put(Uri.parse('$clientBaseUrl/$id'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'id': id, 'title': title, 'body': body, 'userId': 1}));
    if (res.statusCode != 200) throw Exception('Failed to update (${res.statusCode})');
  }

  static Future<void> delete(int id) async {
    final res = await http.delete(Uri.parse('$clientBaseUrl/$id'));
    if (res.statusCode != 200) throw Exception('Failed to delete (${res.statusCode})');
  }
}
