import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class ClientFirestoreService {
  static final CollectionReference<Map<String, dynamic>> _collection =
  FirebaseFirestore.instance.collection('clients');

  static Future<List<Client>> readAll() async {
    try {
      final snapshot = await _collection.orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => Client.fromFirestore(doc.id, doc.data())).toList();
    } catch (e) {
      throw Exception('Could not load clients: $e');
    }
  }

  static Future<Client> create(String title, String body) async {
    try {
      final data = {
        'title': title,
        'body': body,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final docRef = await _collection.add(data);
      return Client(id: docRef.id, title: title, body: body);
    } catch (e) {
      throw Exception('Could not save client: $e');
    }
  }

  static Future<void> update(String id, String title, String body) async {
    try {
      await _collection.doc(id).update({'title': title, 'body': body});
    } catch (e) {
      throw Exception('Could not update client: $e');
    }
  }

  static Future<void> delete(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw Exception('Could not delete client: $e');
    }
  }
}