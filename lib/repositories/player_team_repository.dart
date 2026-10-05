import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_team_model.dart';

class PlayerTeamRepository {
  final FirebaseFirestore _firestore;

  PlayerTeamRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _playerTeams =>
      _firestore.collection('player_teams');

  Future<void> savePlayerTeam(
    PlayerTeamModel playerTeam,
  ) async {
    await _playerTeams
        .doc(playerTeam.id)
        .set(playerTeam.toMap());
  }

  Future<PlayerTeamModel?> getPlayerTeam(
    String playerTeamId,
  ) async {
    final snapshot =
        await _playerTeams.doc(playerTeamId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return PlayerTeamModel.fromMap(snapshot.data()!);
  }

  Future<List<PlayerTeamModel>> getTeamsForPlayer(
    String playerId,
  ) async {
    final snapshot = await _playerTeams
        .where('playerId', isEqualTo: playerId)
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => PlayerTeamModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<PlayerTeamModel>> getPlayersForTeam(
    String teamId,
  ) async {
    final snapshot = await _playerTeams
        .where('teamId', isEqualTo: teamId)
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => PlayerTeamModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<void> updatePlayerTeam(
    PlayerTeamModel playerTeam,
  ) async {
    await _playerTeams
        .doc(playerTeam.id)
        .update(playerTeam.toMap());
  }

  Future<void> deletePlayerTeam(
    String playerTeamId,
  ) async {
    await _playerTeams
        .doc(playerTeamId)
        .delete();
  }
}