import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/player_match_performance_model.dart';

class PlayerMatchPerformanceRepository {
  final FirebaseFirestore _firestore;

  PlayerMatchPerformanceRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _performances =>
      _firestore.collection('player_match_performances');

  Future<void> savePerformance(
    PlayerMatchPerformanceModel performance,
  ) async {
    await _performances
        .doc(performance.id)
        .set(performance.toMap());
  }

  Future<PlayerMatchPerformanceModel?> getPerformance(
    String performanceId,
  ) async {
    final snapshot =
        await _performances.doc(performanceId).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return PlayerMatchPerformanceModel.fromMap(
      snapshot.data()!,
    );
  }

  Future<List<PlayerMatchPerformanceModel>>
      getPerformancesForMatch(
    String matchId,
  ) async {
    final snapshot = await _performances
        .where(
          'matchId',
          isEqualTo: matchId,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              PlayerMatchPerformanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<PlayerMatchPerformanceModel>>
      getPerformancesForPlayer(
    String playerId,
  ) async {
    final snapshot = await _performances
        .where(
          'playerId',
          isEqualTo: playerId,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              PlayerMatchPerformanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<PlayerMatchPerformanceModel>>
      getPerformancesForTeam(
    String teamId,
  ) async {
    final snapshot = await _performances
        .where(
          'teamId',
          isEqualTo: teamId,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              PlayerMatchPerformanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<List<PlayerMatchPerformanceModel>>
      getPerformancesForPlayerAndTeam(
    String playerId,
    String teamId,
  ) async {
    final snapshot = await _performances
        .where(
          'playerId',
          isEqualTo: playerId,
        )
        .where(
          'teamId',
          isEqualTo: teamId,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) =>
              PlayerMatchPerformanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  Future<void> updatePerformance(
    PlayerMatchPerformanceModel performance,
  ) async {
    await _performances
        .doc(performance.id)
        .update(performance.toMap());
  }

  Future<void> deletePerformance(
    String performanceId,
  ) async {
    await _performances.doc(performanceId).delete();
  }

  Future<void> deletePerformancesForMatch(
    String matchId,
  ) async {
    if (matchId.trim().isEmpty) {
      return;
    }

    final snapshot = await _performances
        .where(
          'matchId',
          isEqualTo: matchId,
        )
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    const batchSize = 400;

    for (var start = 0;
        start < snapshot.docs.length;
        start += batchSize) {
      final end = (start + batchSize < snapshot.docs.length)
          ? start + batchSize
          : snapshot.docs.length;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs.sublist(start, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }
}