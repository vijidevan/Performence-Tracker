import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_bowling_parser.dart';
import 'package:team_performance/services/stumps_fielding_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';
import 'package:team_performance/services/stumps_performance_builder.dart';

void main() {
  test('inspect performance builder output', () async {
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
      matchId: 'paow1610',
      team1Id: 'team-rockers',
      team1Name: 'KELAMBAKKAM SUPER KINGS',
      team2Id: 'team-thunders',
      team2Name: 'ST MARYS TITANS',
      batting: batting,
      bowling: bowling,
      fielding: fielding,
    );

    print('');
    print('==========================================');
    print('PERFORMANCE BUILDER OUTPUT');
    print('==========================================');

    for (final performance in performances) {
      print(
        '${performance.playerId} | '
        'Team: ${performance.teamId} | '
        'Runs: ${performance.runs} | '
        'Wickets: ${performance.wickets} | '
        'Catches: ${performance.catches} | '
        'Caught&Bowled: ${performance.caughtAndBowled} | '
        'Run-outs: ${performance.runOuts} | '
        'Stumpings: ${performance.stumpings}',
      );
    }

    print('');
    print('TOTAL PERFORMANCES: ${performances.length}');
    print('==========================================');

    expect(performances.length, 24);
  });
}

Future<Uint8List> _loadFixture() async {
  final file = File(
    'test/fixtures/kelambakkam_st_marys_match.pdf',
  );

  return Uint8List.fromList(
    await file.readAsBytes(),
  );
}
