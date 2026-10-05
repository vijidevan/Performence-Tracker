import 'dart:io';

import '../lib/services/stumps_match_parser.dart';
import '../lib/services/stumps_pdf_parser.dart';

Future<void> main() async {
  final pdfPath =
      '${Platform.environment['USERPROFILE']}\\Downloads\\Stumps_Match_Report (1).pdf';

  final file = File(pdfPath);

  if (!file.existsSync()) {
    stderr.writeln('PDF NOT FOUND: $pdfPath');
    exitCode = 1;
    return;
  }

  final bytes = await file.readAsBytes();

  final pdfParser = StumpsPdfParser();
  final matchParser = StumpsMatchParser();

  final text = await pdfParser.extractText(bytes);
  final lines = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  stdout.writeln('');
  stdout.writeln('========== STUMPS PDF DIAGNOSTIC ==========');
  stdout.writeln('PDF: $pdfPath');
  stdout.writeln('Extracted lines: ${lines.length}');
  stdout.writeln('');

  stdout.writeln('---------- LINES AROUND TOSS ----------');

  final tossIndexes = <int>[];

  for (int i = 0; i < lines.length; i++) {
    if (lines[i].toLowerCase().contains('toss') ||
        lines[i].toLowerCase().contains('opted')) {
      tossIndexes.add(i);
    }
  }

  if (tossIndexes.isEmpty) {
    stdout.writeln('NO LINE CONTAINING "TOSS" OR "OPTED" WAS FOUND.');
  } else {
    final printed = <int>{};

    for (final index in tossIndexes) {
      final start = index - 5 < 0 ? 0 : index - 5;
      final end =
          index + 8 >= lines.length ? lines.length - 1 : index + 8;

      for (int i = start; i <= end; i++) {
        if (printed.add(i)) {
          stdout.writeln('[$i] ${lines[i]}');
        }
      }

      stdout.writeln('------------------------------------------');
    }
  }

  stdout.writeln('');
  stdout.writeln('---------- PARSED MATCH INFO ----------');

  final matchInfo = matchParser.parseMatchInfo(text);

  matchInfo.forEach((key, value) {
    stdout.writeln('$key = <$value>');
  });

  stdout.writeln('');
  stdout.writeln('========== END DIAGNOSTIC ==========');
}
