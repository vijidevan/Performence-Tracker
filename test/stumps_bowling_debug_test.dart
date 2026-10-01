import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_bowling_parser.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('inspect bowling records', () async {
    final file = File(
      'test/fixtures/stumps_match_report.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();

    final text = await StumpsPdfParser().extractText(
      pdfBytes,
    );

    final bowling = StumpsBowlingParser().parseBowling(text);

    print('========== BOWLING RECORDS ==========');
    for (final record in bowling) {
      print(record);
    }
  });
}
