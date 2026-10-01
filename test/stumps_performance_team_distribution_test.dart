import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_bowling_parser.dart';
import 'package:team_performance/services/stumps_fielding_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';
import 'package:team_performance/services/stumps_performance_builder.dart';

void main() {
  test('inspect team distribution', () async {
    final pdfParser = StumpsPdfParser();
    final battingParser = StumpsBattingParser();
    final bowlingParser = StumpsBowlingParser();
    final fieldingParser = StumpsFieldingParser();
    final performanceBuilder = StumpsPerformanceBuilder();

    final pdfBytes = await _loadFixture();

    final text = await pdfParser.extractText(pdfBytes);

    final batting = battingParser.parseBatting(text);

    final bowling = bowlingParser.parseBowling(text);

    final fielding = fieldingParser.parseFielding(batting);

    final performances = performanceBuilder.build(
      matchId: 'gcuk7979',
      team1Id: 'team-rockers',
      team1Name: 'ROCKERS ROCK4381',
      team2Id: 'team-thunders',
      team2Name: 'THUNDERS 11',
      batting: batting,
      bowling: bowling,
      fielding: fielding,
    );

    final rockers = performances
        .where(
          (performance) => performance.teamId == 'team-rockers',
        )
        .toList();

    final thunders = performances
        .where(
          (performance) => performance.teamId == 'team-thunders',
        )
        .toList();

    print('');
    print('==========================================');
    print('ROCKERS RECORDS: ${rockers.length}');
    print('==========================================');

    for (final performance in rockers) {
      print(
        '${performance.playerId} | '
        'Runs: ${performance.runs} | '
        'Wickets: ${performance.wickets} | '
        'Catches: ${performance.catches} | '
        'Caught&Bowled: ${performance.caughtAndBowled} | '
        'Run-outs: ${performance.runOuts}',
      );
    }

    print('');
    print('==========================================');
    print('THUNDERS RECORDS: ${thunders.length}');
    print('==========================================');

    for (final performance in thunders) {
      print(
        '${performance.playerId} | '
        'Runs: ${performance.runs} | '
        'Wickets: ${performance.wickets} | '
        'Catches: ${performance.catches} | '
        'Caught&Bowled: ${performance.caughtAndBowled} | '
        'Run-outs: ${performance.runOuts}',
      );
    }

    print('');
    print('==========================================');
    print('TOTAL RECORDS: ${performances.length}');
    print('==========================================');

    expect(rockers.length, 11);
    expect(thunders.length, 11);
    expect(performances.length, 22);
  });
}

Future<Uint8List> _loadFixture() async {
  final file = File(
    'test/fixtures/stumps_match_report.pdf',
  );

  return Uint8List.fromList(
    await file.readAsBytes(),
  );
}