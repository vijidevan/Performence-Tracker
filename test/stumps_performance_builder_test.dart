import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_bowling_parser.dart';
import 'package:team_performance/services/stumps_fielding_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test(
    'builds player performance data from actual STUMPS PDF',
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

      final battingParser = StumpsBattingParser();
      final bowlingParser = StumpsBowlingParser();
      final fieldingParser = StumpsFieldingParser();

      final batting = battingParser.parseBatting(
        text,
      );

      final bowling = bowlingParser.parseBowling(
        text,
      );

      final fielding = fieldingParser.parseFielding(
        batting,
      );

      expect(batting, isNotEmpty);
      expect(bowling, isNotEmpty);
      expect(fielding, isNotEmpty);

      final pugazdhoniBatting = batting.firstWhere(
        (player) =>
            player['playerName'] == 'Pugazdhoni' &&
            player['teamName'] == 'ROCKERS ROCK4381',
      );

      expect(
        pugazdhoniBatting['runs'],
        35,
      );

      final raviBowling = bowling.firstWhere(
        (player) =>
            player['playerName'] == 'Ravi',
      );

      expect(
        raviBowling['wickets'],
        4,
      );

      expect(
        raviBowling['runsConceded'],
        14,
      );

      final fieldingCatch = fielding.firstWhere(
        (event) =>
            event['playerName'] == 'Karthick E' &&
            event['eventType'] == 'catch',
      );

      expect(
        fieldingCatch['dismissedPlayer'],
        'Arun V',
      );

      final runOutEvents = fielding.where(
        (event) =>
            event['eventType'] == 'run_out' &&
            event['dismissedPlayer'] == 'Dheena',
      ).toList();

      expect(
        runOutEvents.length,
        2,
      );
    },
  );
}
