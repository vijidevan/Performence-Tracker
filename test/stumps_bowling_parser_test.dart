import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('extracts bowling section from actual STUMPS PDF', () async {
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

    expect(text, contains('Bowler'));
    expect(text, contains('Ravi'));
    expect(text, contains('Vignesh'));
    expect(text, contains('W'));
    expect(text, contains('Eco'));
  });
}
