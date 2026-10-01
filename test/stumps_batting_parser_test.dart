import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('parses batting data from actual STUMPS PDF', () async {
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

    final batting = battingParser.parseBatting(text);

    expect(batting, isNotEmpty);

    final pugazdhoni = batting.firstWhere(
      (player) =>
          player['playerName'] == 'Pugazdhoni' &&
          player['teamName'] == 'ROCKERS ROCK4381',
    );

    expect(pugazdhoni['runs'], 35);
    expect(pugazdhoni['ballsFaced'], 36);
    expect(pugazdhoni['fours'], 1);
    expect(pugazdhoni['sixes'], 2);
    expect(pugazdhoni['strikeRate'], 97.2);
    expect(
      pugazdhoni['dismissal'],
      'b Ashraf',
    );

    final subash = batting.firstWhere(
      (player) =>
          player['playerName'] == 'Subash' &&
          player['teamName'] == 'THUNDERS 11',
    );

    expect(subash['runs'], 30);
    expect(subash['ballsFaced'], 23);
    expect(subash['fours'], 4);
    expect(subash['sixes'], 0);
    expect(subash['strikeRate'], 130.4);

    final totalPlayers = batting.length;

    expect(
      totalPlayers,
      greaterThanOrEqualTo(20),
    );
  });
}
