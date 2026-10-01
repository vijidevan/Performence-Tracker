import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_bowling_parser.dart';
import 'package:team_performance/services/stumps_fielding_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';
import 'package:team_performance/services/stumps_performance_builder.dart';

void main() {
  test(
    'builds PlayerMatchPerformanceModel records from STUMPS PDF',
    () async {
      final file = File(
        'test/fixtures/stumps_match_report.pdf',
      );

      expect(
        file.existsSync(),
        isTrue,
        reason: 'STUMPS PDF fixture was not found.',
      );

      final Uint8List pdfBytes = await file.readAsBytes();

      final pdfParser = StumpsPdfParser();

      final text = await pdfParser.extractText(
        pdfBytes,
      );

      final batting = StumpsBattingParser()
          .parseBatting(text);

      final bowling = StumpsBowlingParser()
          .parseBowling(text);

      final fielding = StumpsFieldingParser()
          .parseFielding(batting);

      final builder = StumpsPerformanceBuilder();

      final performances = builder.build(
       matchId: 'gcuk7979',
       team1Id: 'team-rockers',
       team1Name: 'ROCKERS ROCK4381',
       team2Id: 'team-thunders',
       team2Name: 'THUNDERS 11',
       batting: batting,
       bowling: bowling,
       fielding: fielding,
      );

      expect(
        performances,
        isNotEmpty,
      );

      final pugazdhoni = performances.firstWhere(
        (performance) =>
            performance.playerId == 'Pugazdhoni',
      );

      expect(
        pugazdhoni.matchId,
        'gcuk7979',
      );

      expect(
        pugazdhoni.teamId,
        'team-rockers',
      );

      expect(
        pugazdhoni.runs,
        35,
      );

      expect(
        pugazdhoni.ballsFaced,
        36,
      );

      final ravi = performances.firstWhere(
        (performance) =>
            performance.playerId == 'Ravi',
      );

      expect(
        ravi.wickets,
        4,
      );

      expect(
        ravi.runsConceded,
        14,
      );

      final arun = performances.firstWhere(
        (performance) =>
            performance.playerId == 'Arun V',
      );

      expect(
        arun.catches,
        2,
      );

      final totalPerformances = performances.length;

      expect(
        totalPerformances,
        greaterThanOrEqualTo(20),
      );
    },
  );
}
