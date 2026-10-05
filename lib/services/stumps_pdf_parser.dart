import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class StumpsPdfParser {
  Future<String> extractText(Uint8List pdfBytes) async {
    PdfDocument? document;

    try {
      document = PdfDocument(inputBytes: pdfBytes);

      final buffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final page = document.pages[i];

        final text = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );

        if (text.trim().isNotEmpty) {
          buffer.writeln(text.trim());
          buffer.writeln();
        }
      }

      final extractedText = buffer.toString().trim();

      // STUMPS PDFs contain a standalone "Report" heading.
      // Remove only that standalone heading so it cannot
      // become part of the first team's name.
      final cleanedLines = extractedText
          .split(RegExp(r'\r?\n'))
          .where(
            (line) => line.trim().toLowerCase() != 'report',
          )
          .toList();

      return cleanedLines.join('\n').trim();
    } finally {
      document?.dispose();
    }
  }
}