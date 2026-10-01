import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('debug actual STUMPS PDF extracted text', () async {
    final file = File(
      'test/fixtures/stumps_match_report.pdf',
    );

    final bytes = Uint8List.fromList(
      await file.readAsBytes(),
    );

    final parser = StumpsPdfParser();

    final text = await parser.extractText(bytes);

    print('');
    print('================ STUMPS PDF TEXT ================');
    print(text);
    print('=================================================');
    print('');
  });
}