import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('reads ST MARYS TITANS STUMPS PDF', () async {
    final file = File(
      'test/fixtures/kelambakkam_st_marys_match.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();
    final parser = StumpsPdfParser();
    final text = await parser.extractText(pdfBytes);

    print('========== ST MARYS PDF TEXT ==========');
    print(text);
    print('========== END ST MARYS PDF TEXT ==========');
  });
}
