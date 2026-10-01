import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_fielding_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('inspect caught and bowled event', () async {
    final file = File(
      'test/fixtures/stumps_match_report.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();

    final text = await StumpsPdfParser().extractText(
      pdfBytes,
    );

    final batting = StumpsBattingParser().parseBatting(text);
    final fielding = StumpsFieldingParser().parseFielding(batting);

    print('========== CAUGHT AND BOWLED ==========');

    for (final event in fielding) {
      if (event['eventType'] == 'caught_and_bowled') {
        print(event);
      }
    }
  });
}
