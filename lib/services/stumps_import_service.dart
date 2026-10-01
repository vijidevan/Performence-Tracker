import 'dart:typed_data';

import '../models/match_model.dart';
import '../models/player_match_performance_model.dart';
import '../models/player_model.dart';
import '../models/player_team_model.dart';
import '../models/team_model.dart';
import '../repositories/match_repository.dart';
import '../repositories/player_match_performance_repository.dart';
import '../repositories/player_repository.dart';
import '../repositories/player_team_repository.dart';
import '../repositories/team_repository.dart';
import 'stumps_batting_parser.dart';
import 'stumps_bowling_parser.dart';
import 'stumps_fielding_parser.dart';
import 'stumps_match_parser.dart';
import 'stumps_pdf_parser.dart';
import 'stumps_performance_builder.dart';

class StumpsImportService {
  final StumpsPdfParser _pdfParser;
  final StumpsMatchParser _matchParser;
  final StumpsBattingParser _battingParser;
  final StumpsBowlingParser _bowlingParser;
  final StumpsFieldingParser _fieldingParser;
  final StumpsPerformanceBuilder _performanceBuilder;

  final MatchRepository _matchRepository;
  final TeamRepository _teamRepository;
  final PlayerRepository _playerRepository;
  final PlayerTeamRepository _playerTeamRepository;
  final PlayerMatchPerformanceRepository _performanceRepository;

  StumpsImportService({
    StumpsPdfParser? pdfParser,
    StumpsMatchParser? matchParser,
    StumpsBattingParser? battingParser,
    StumpsBowlingParser? bowlingParser,
    StumpsFieldingParser? fieldingParser,
    StumpsPerformanceBuilder? performanceBuilder,
    MatchRepository? matchRepository,
    TeamRepository? teamRepository,
    PlayerRepository? playerRepository,
    PlayerTeamRepository? playerTeamRepository,
    PlayerMatchPerformanceRepository? performanceRepository,
  })  : _pdfParser = pdfParser ?? StumpsPdfParser(),
        _matchParser = matchParser ?? StumpsMatchParser(),
        _battingParser = battingParser ?? StumpsBattingParser(),
        _bowlingParser = bowlingParser ?? StumpsBowlingParser(),
        _fieldingParser = fieldingParser ?? StumpsFieldingParser(),
        _performanceBuilder =
            performanceBuilder ?? StumpsPerformanceBuilder(),
        _matchRepository = matchRepository ?? MatchRepository(),
        _teamRepository = teamRepository ?? TeamRepository(),
        _playerRepository = playerRepository ?? PlayerRepository(),
        _playerTeamRepository =
            playerTeamRepository ?? PlayerTeamRepository(),
        _performanceRepository =
            performanceRepository ??
                PlayerMatchPerformanceRepository();

  Future<StumpsImportResult> importPdf(
    Uint8List pdfBytes,
  ) async {
    if (pdfBytes.isEmpty) {
      throw ArgumentError('The STUMPS PDF is empty.');
    }

    final text = await _pdfParser.extractText(pdfBytes);

    if (text.trim().isEmpty) {
      throw StateError(
        'No readable text was found in the STUMPS PDF.',
      );
    }

    final matchInfo = _matchParser.parseMatchInfo(text);

    final stumpsMatchId =
        (matchInfo['stumpsMatchId'] ?? '').toString().trim();

    if (stumpsMatchId.isEmpty) {
      throw StateError(
        'STUMPS Match ID was not found in the PDF.',
      );
    }

    // Duplicate protection.
    final existingMatch =
        await _matchRepository.getMatchByStumpsId(
      stumpsMatchId,
    );

    if (existingMatch != null) {
      final existingPerformances =
          await _performanceRepository.getPerformancesForMatch(
        existingMatch.id,
      );

      return StumpsImportResult(
        status: StumpsImportStatus.duplicate,
        match: existingMatch,
        performanceCount: existingPerformances.length,
      );
    }

    final team1Name =
        (matchInfo['team1'] ?? '').toString().trim();

    final team2Name =
        (matchInfo['team2'] ?? '').toString().trim();

    if (team1Name.isEmpty || team2Name.isEmpty) {
      throw StateError(
        'Both team names must be present in the STUMPS match report.',
      );
    }

    final team1 = await _getOrCreateTeam(
      teamName: team1Name,
    );

    final team2 = await _getOrCreateTeam(
      teamName: team2Name,
    );

    final batting =
        _battingParser.parseBatting(text);

    final bowling =
        _bowlingParser.parseBowling(text);

    final fielding =
        _fieldingParser.parseFielding(batting);

    final matchId =
        _createDocumentId('match', stumpsMatchId);

    // Toss information is intentionally optional.
    // The STUMPS import does not depend on a toss winner being present
    // or resolvable. Match analytics use teams and performance data.
    const tossWinnerTeamId = '';
    final tossDecision =
        (matchInfo['tossDecision'] ?? '').toString().trim();

    final match = MatchModel(
      id: matchId,
      stumpsMatchId: stumpsMatchId,
      team1Id: team1.id,
      team2Id: team2.id,
      matchDate: _parseDate(
        matchInfo['matchDate'],
      ),
      format: (matchInfo['format'] ?? '').toString(),
      overs: _parseInt(matchInfo['overs']),
      venue: (matchInfo['venue'] ?? '').toString(),
      tossWinnerTeamId: tossWinnerTeamId,
      tossDecision: tossDecision,
      result: (matchInfo['result'] ?? '').toString(),
      organiser:
          (matchInfo['organiser'] ?? '').toString(),
      scorer:
          (matchInfo['scorer'] ?? '').toString(),
      completed: true,
      createdAt: DateTime.now(),
    );

    final builtPerformances =
        _performanceBuilder.build(
      matchId: match.id,
      team1Id: team1.id,
      team1Name: team1.name,
      team2Id: team2.id,
      team2Name: team2.name,
      batting: batting,
      bowling: bowling,
      fielding: fielding,
    );

    final resolvedPerformances =
        <PlayerMatchPerformanceModel>[];

    for (final performance in builtPerformances) {
      final playerName = performance.playerId.trim();

      if (playerName.isEmpty) {
        throw StateError(
          'A performance record contains an empty player name.',
        );
      }

      final player =
          await _getOrCreatePlayer(playerName);

      await _ensurePlayerTeam(
        playerId: player.id,
        teamId: performance.teamId,
      );

      final resolvedPerformance =
          performance.copyWith(
        id:
            '${match.id}_${performance.teamId}_${player.id}',
        playerId: player.id,
      );

      resolvedPerformances.add(
        resolvedPerformance,
      );
    }

    await _matchRepository.saveMatch(match);

    for (final performance in resolvedPerformances) {
      await _performanceRepository.savePerformance(
        performance,
      );
    }

    return StumpsImportResult(
      status: StumpsImportStatus.imported,
      match: match,
      performanceCount: resolvedPerformances.length,
    );
  }

  Future<TeamModel> _getOrCreateTeam({
    required String teamName,
  }) async {
    final normalizedName = teamName.trim();

    if (normalizedName.isEmpty) {
      throw StateError(
        'A team name cannot be empty.',
      );
    }

    final existing =
        await _teamRepository.getTeamByName(
      normalizedName,
    );

    if (existing != null) {
      return existing;
    }

    final team = TeamModel(
      id: _createDocumentId(
        'team',
        normalizedName,
      ),
      name: normalizedName,
      active: false,
      createdAt: DateTime.now(),
    );

    await _teamRepository.saveTeam(team);

    return team;
  }

  Future<PlayerModel> _getOrCreatePlayer(
    String playerName,
  ) async {
    final normalizedName = playerName.trim();

    final existing =
        await _playerRepository.getPlayerByName(
      normalizedName,
    );

    if (existing != null) {
      return existing;
    }

    final player = PlayerModel(
      id: _createDocumentId(
        'player',
        normalizedName,
      ),
      name: normalizedName,
      active: true,
      createdAt: DateTime.now(),
    );

    await _playerRepository.savePlayer(player);

    return player;
  }

  Future<void> _ensurePlayerTeam({
    required String playerId,
    required String teamId,
  }) async {
    final existingRelationships =
        await _playerTeamRepository.getTeamsForPlayer(
      playerId,
    );

    final alreadyLinked =
        existingRelationships.any(
      (relationship) =>
          relationship.teamId == teamId &&
          relationship.active,
    );

    if (alreadyLinked) {
      return;
    }

    final playerTeam = PlayerTeamModel(
      id: '${playerId}_$teamId',
      playerId: playerId,
      teamId: teamId,
      active: true,
      joinedAt: DateTime.now(),
    );

    await _playerTeamRepository.savePlayerTeam(
      playerTeam,
    );
  }

  String _createDocumentId(
    String prefix,
    String value,
  ) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'^_+|_+$'),
          '',
        );

    return '${prefix}_$normalized';
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    final text =
        value?.toString().trim() ?? '';

    final parsed = DateTime.tryParse(text);

    return parsed ?? DateTime.now();
  }

  int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString().trim() ?? '',
        ) ??
        0;
  }
}

enum StumpsImportStatus {
  imported,
  duplicate,
}

class StumpsImportResult {
  final StumpsImportStatus status;
  final MatchModel match;
  final int performanceCount;

  const StumpsImportResult({
    required this.status,
    required this.match,
    required this.performanceCount,
  });

  bool get wasImported =>
      status == StumpsImportStatus.imported;

  bool get wasDuplicate =>
      status == StumpsImportStatus.duplicate;
}
