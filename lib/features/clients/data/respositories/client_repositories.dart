import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crm_app/features/clients/domain/models/client.dart';

class ClientRepository {
  final FirebaseFirestore _firestore;

  ClientRepository(this._firestore);

  // Create or update a client
  Future<void> saveClient(Client client) async {
    await _firestore.collection('clients').doc(client.id).set(client.toMap());
  }

  // Fetch all clients
  Future<List<Client>> fetchClients() async {
    final snapshot = await _firestore.collection('clients').get();
    return snapshot.docs.map((doc) => Client.fromMap(doc.data())).toList();
  }

  // Delete a client
  Future<void> deleteClient(String id) async {
    await _firestore.collection('clients').doc(id).delete();
  }
}

