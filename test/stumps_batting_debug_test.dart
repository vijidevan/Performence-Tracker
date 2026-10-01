import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_batting_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('prints parsed batting records', () async {
    final file = File(
      'test/fixtures/kelambakkam_st_marys_match.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();

    final pdfParser = StumpsPdfParser();
    final text = await pdfParser.extractText(pdfBytes);

    final battingParser = StumpsBattingParser();
    final batting = battingParser.parseBatting(text);

    print('========== PARSED BATTING ==========');
    print('COUNT: ${batting.length}');

    for (final player in batting) {
      print(player);
    }

    print('========== END PARSED BATTING ==========');
  });
}
