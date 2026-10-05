import '../models/player_match_performance_model.dart';

class StumpsPerformanceBuilder {
  List<PlayerMatchPerformanceModel> build({
    required String matchId,
    required String team1Id,
    required String team1Name,
    required String team2Id,
    required String team2Name,
    required List<Map<String, dynamic>> batting,
    required List<Map<String, dynamic>> bowling,
    required List<Map<String, dynamic>> fielding,
  }) {
    final players = <String>{};

    for (final player in batting) {
      final name = player['playerName'] as String? ?? '';

      if (name.isNotEmpty) {
        players.add(name);
      }
    }

    for (final player in bowling) {
      final name = player['playerName'] as String? ?? '';

      if (name.isNotEmpty) {
        players.add(name);
      }
    }

    for (final event in fielding) {
      final name = event['playerName'] as String? ?? '';

      if (name.isNotEmpty) {
        players.add(name);
      }
    }

    final results = <PlayerMatchPerformanceModel>[];
    final now = DateTime.now();

    for (final playerId in players) {
      final battingRecord = _findByPlayer(
        batting,
        playerId,
      );

      final bowlingRecord = _findByPlayer(
        bowling,
        playerId,
      );

      final teamId = _resolveTeamId(
        playerId: playerId,
        battingRecord: battingRecord,
        bowlingRecord: bowlingRecord,
        fielding: fielding,
        team1Id: team1Id,
        team1Name: team1Name,
        team2Id: team2Id,
        team2Name: team2Name,
      );

      if (teamId == null) {
        continue;
      }

      final fieldingRecords = fielding
          .where(
            (event) =>
                event['playerName'] == playerId &&
                _fieldingTeamId(
                      _intValue(event['innings']),
                      team1Id,
                      team2Id,
                    ) ==
                    teamId,
          )
          .toList();

      results.add(
        PlayerMatchPerformanceModel(
          id: '${matchId}_${teamId}_$playerId',
          matchId: matchId,
          playerId: playerId,
          teamId: teamId,
          runs: _intValue(
            battingRecord?['runs'],
          ),
          ballsFaced: _intValue(
            battingRecord?['ballsFaced'],
          ),
          fours: _intValue(
            battingRecord?['fours'],
          ),
          sixes: _intValue(
            battingRecord?['sixes'],
          ),
          strikeRate: _doubleValue(
            battingRecord?['strikeRate'],
          ),
          dismissal:
              battingRecord?['dismissal'] as String? ?? '',
          overs: _doubleValue(
            bowlingRecord?['overs'],
          ),
          maidens: _intValue(
            bowlingRecord?['maidens'],
          ),
          runsConceded: _intValue(
            bowlingRecord?['runsConceded'],
          ),
          wickets: _intValue(
            bowlingRecord?['wickets'],
          ),
          economy: _doubleValue(
            bowlingRecord?['economy'],
          ),
          dotBalls: _intValue(
            bowlingRecord?['dotBalls'],
          ),
          bowlingFours: _intValue(
            bowlingRecord?['fours'],
          ),
          bowlingSixes: _intValue(
            bowlingRecord?['sixes'],
          ),
          wides: _intValue(
            bowlingRecord?['wides'],
          ),
          noBalls: _intValue(
            bowlingRecord?['noBalls'],
          ),
          catches: _countEvents(
            fieldingRecords,
            'catch',
          ),
          caughtAndBowled: _countEvents(
            fieldingRecords,
            'caught_and_bowled',
          ),
          runOuts: _countEvents(
            fieldingRecords,
            'run_out',
          ),
          stumpings: _countEvents(
            fieldingRecords,
            'stumping',
          ),
          createdAt: now,
        ),
      );
    }

    return results;
  }

  String? _resolveTeamId({
    required String playerId,
    required Map<String, dynamic>? battingRecord,
    required Map<String, dynamic>? bowlingRecord,
    required List<Map<String, dynamic>> fielding,
    required String team1Id,
    required String team1Name,
    required String team2Id,
    required String team2Name,
  }) {
    if (battingRecord != null) {
      final teamName =
          battingRecord['teamName'] as String? ?? '';

      if (_teamNamesMatch(teamName, team1Name)) {
        return team1Id;
      }

      if (_teamNamesMatch(teamName, team2Name)) {
        return team2Id;
      }
    }

    if (bowlingRecord != null) {
      final innings = _intValue(
        bowlingRecord['innings'],
      );

      return _fieldingTeamId(
        innings,
        team1Id,
        team2Id,
      );
    }

    for (final event in fielding) {
      if (event['playerName'] != playerId) {
        continue;
      }

      final innings = _intValue(
        event['innings'],
      );

      final resolvedTeamId = _fieldingTeamId(
        innings,
        team1Id,
        team2Id,
      );

      if (resolvedTeamId != null) {
        return resolvedTeamId;
      }
    }

    return null;
  }

  bool _teamNamesMatch(
    String parsedName,
    String matchName,
  ) {
    final parsed = _normalizeTeamName(parsedName);
    final match = _normalizeTeamName(matchName);

    if (parsed.isEmpty || match.isEmpty) {
      return false;
    }

    if (parsed == match) {
      return true;
    }

    return parsed.endsWith(' $match') ||
        match.endsWith(' $parsed');
  }

  String _normalizeTeamName(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  String? _fieldingTeamId(
    int innings,
    String team1Id,
    String team2Id,
  ) {
    if (innings == 1) {
      return team2Id;
    }

    if (innings == 2) {
      return team1Id;
    }

    return null;
  }

  Map<String, dynamic>? _findByPlayer(
    List<Map<String, dynamic>> records,
    String playerId,
  ) {
    for (final record in records) {
      if (record['playerName'] == playerId) {
        return record;
      }
    }

    return null;
  }

  int _countEvents(
    List<Map<String, dynamic>> events,
    String eventType,
  ) {
    return events
        .where(
          (event) =>
              event['eventType'] == eventType,
        )
        .length;
  }

  int _intValue(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0.0;
  }
}
