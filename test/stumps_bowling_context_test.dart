import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:team_performance/services/stumps_pdf_parser.dart';

void main() {
  test('inspect bowling section context', () async {
    final file = File(
      'test/fixtures/stumps_match_report.pdf',
    );

    final Uint8List pdfBytes = await file.readAsBytes();

    final text = await StumpsPdfParser().extractText(
      pdfBytes,
    );

    final tokens = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    print('========== BOWLING HEADER CONTEXT ==========');

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].toLowerCase() != 'bowler') {
        continue;
      }

      if (i + 10 >= tokens.length) {
        continue;
      }

      final header = [
        'Bowler',
        'O',
        'M',
        'R',
        'W',
        'Eco',
        '0s',
        '4s',
        '6s',
        'Wd',
        'NB',
      ];

      bool isHeader = true;

      for (int j = 0; j < header.length; j++) {
        if (tokens[i + j].toLowerCase() !=
            header[j].toLowerCase()) {
          isHeader = false;
          break;
        }
      }

      if (!isHeader) {
        continue;
      }

      print('');
      print('----- BOWLING HEADER AT TOKEN $i -----');

      final start = i >= 12 ? i - 12 : 0;
      final end = i + 35 < tokens.length
          ? i + 35
          : tokens.length;

      for (int j = start; j < end; j++) {
        print('$j: ${tokens[j]}');
      }
    }
  });
}
