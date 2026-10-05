import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('extracts fielding events from actual STUMPS PDF', () async {
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

    final dheena = batting.firstWhere(
      (player) =>
          player['playerName'] == 'Dheena',
    );

    expect(
      dheena['dismissal'],
      'runout (Ashraf/Yesudhasan)',
    );

    final arun = batting.firstWhere(
      (player) =>
          player['playerName'] == 'Arun V',
    );

    expect(
      arun['dismissal'],
      'c Karthick E b Ravi',
    );

    final umapathi = batting.firstWhere(
      (player) =>
          player['playerName'] == 'Umapathi',
    );

    expect(
      umapathi['dismissal'],
      'c & b Yesudhasan',
    );
  });
}
