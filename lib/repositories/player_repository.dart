import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_model.dart';

class PlayerRepository {
  final FirebaseFirestore _firestore;

  PlayerRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _players =>
      _firestore.collection('players');

  Future<void> savePlayer(PlayerModel player) async {
    await _players.doc(player.id).set(player.toMap());
  }

  Future<PlayerModel?> getPlayer(String playerId) async {
    final snapshot = await _players.doc(playerId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return PlayerModel.fromMap(snapshot.data()!);
  }

  Future<PlayerModel?> getPlayerByName(String name) async {
    final snapshot = await _players
        .where(
          'name',
          isEqualTo: name,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return PlayerModel.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<List<PlayerModel>> getAllPlayers() async {
    final snapshot = await _players
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => PlayerModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updatePlayer(PlayerModel player) async {
    await _players.doc(player.id).update(player.toMap());
  }

  Future<void> deletePlayer(String playerId) async {
    await _players.doc(playerId).delete();
  }
}