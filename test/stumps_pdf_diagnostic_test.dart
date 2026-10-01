import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('prints extracted STUMPS PDF text', () async {
    final file = File(
      'test/fixtures/stumps_match_report.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();

    final parser = StumpsPdfParser();

    final text = await parser.extractText(pdfBytes);

    print('========== EXTRACTED PDF TEXT ==========');
    print(text);
    print('========== END EXTRACTED TEXT ==========');
  });
}
