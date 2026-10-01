import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/team_model.dart';

class TeamRepository {
  final FirebaseFirestore _firestore;

  TeamRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _teams =>
      _firestore.collection('teams');

  Future<void> saveTeam(TeamModel team) async {
    await _teams.doc(team.id).set(team.toMap());
  }

  Future<TeamModel?> getTeam(String teamId) async {
    final snapshot = await _teams.doc(teamId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return TeamModel.fromMap(snapshot.data()!);
  }

  Future<TeamModel?> getTeamByName(String name) async {
    final snapshot = await _teams
        .where(
          'name',
          isEqualTo: name,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return TeamModel.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<List<TeamModel>> getAllTeams() async {
    final snapshot = await _teams
        .where('active', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => TeamModel.fromMap(doc.data()))
        .toList();
  }

  Future<void> updateTeam(TeamModel team) async {
    await _teams.doc(team.id).update(team.toMap());
  }

  Future<void> deleteTeam(String teamId) async {
    await _teams.doc(teamId).delete();
  }
}