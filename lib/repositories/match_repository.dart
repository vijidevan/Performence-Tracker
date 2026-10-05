import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_model.dart';
import 'player_match_performance_repository.dart';

class MatchRepository {
  final FirebaseFirestore _firestore;
  final PlayerMatchPerformanceRepository _performanceRepository;

  MatchRepository({
    FirebaseFirestore? firestore,
    PlayerMatchPerformanceRepository? performanceRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _performanceRepository = performanceRepository ??
            PlayerMatchPerformanceRepository(
              firestore: firestore ?? FirebaseFirestore.instance,
            );

  CollectionReference<Map<String, dynamic>> get _matches =>
      _firestore.collection('matches');

  Future<void> saveMatch(MatchModel match) async {
    await _matches.doc(match.id).set(match.toMap());
  }

  Future<MatchModel?> getMatch(String matchId) async {
    final snapshot = await _matches.doc(matchId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return MatchModel.fromMap(snapshot.data()!);
  }

  Future<MatchModel?> getMatchByStumpsId(
    String stumpsMatchId,
  ) async {
    final snapshot = await _matches
        .where(
          'stumpsMatchId',
          isEqualTo: stumpsMatchId,
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return MatchModel.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<List<MatchModel>> getAllMatches() async {
    final snapshot = await _matches
        .orderBy('matchDate', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => MatchModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<MatchModel>> getMatchesForTeam(
    String teamId,
  ) async {
    final snapshot = await _matches
        .where(
          'team1Id',
          isEqualTo: teamId,
        )
        .get();

    final team2Snapshot = await _matches
        .where(
          'team2Id',
          isEqualTo: teamId,
        )
        .get();

    final matches = [
      ...snapshot.docs,
      ...team2Snapshot.docs,
    ];

    final uniqueMatches = <String, MatchModel>{};

    for (final doc in matches) {
      final match = MatchModel.fromMap(doc.data());
      uniqueMatches[match.id] = match;
    }

    final result = uniqueMatches.values.toList();

    result.sort(
      (a, b) => b.matchDate.compareTo(a.matchDate),
    );

    return result;
  }

  Future<void> updateMatch(MatchModel match) async {
    await _matches.doc(match.id).update(
          match.toMap(),
        );
  }

  Future<void> deleteMatch(String matchId) async {
    final normalizedMatchId = matchId.trim();

    if (normalizedMatchId.isEmpty) {
      return;
    }

    // Remove all player performance records belonging
    // to this match before deleting the match itself.
    await _performanceRepository.deletePerformancesForMatch(
      normalizedMatchId,
    );

    // Finally remove the match document.
    await _matches.doc(normalizedMatchId).delete();
  }
}