import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Prints a reader's tricky words as a large-print page (screen 11), so a
/// parent can practise them without the phone.
abstract class TrickyWordsPrinter {
  Future<void> print({
    required String title,
    required String hint,
    required List<String> words,
  });
}

/// Builds an A4 PDF with the bundled Nunito font (works offline) and opens
/// Android's print dialog, where the parent can print or save a PDF.
class PdfTrickyWordsPrinter implements TrickyWordsPrinter {
  const PdfTrickyWordsPrinter();

  /// The page as PDF bytes.
  static Future<Uint8List> buildPdf({
    required String title,
    required String hint,
    required List<String> words,
  }) async {
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
    final doc = pw.Document(title: title, author: 'ReadAloud Buddy');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      build: (_) => [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 30)),
        pw.SizedBox(height: 6),
        pw.Text(hint, style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
        pw.SizedBox(height: 24),
        pw.Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final w in words)
              pw.Container(
                width: 240,
                padding: const pw.EdgeInsets.symmetric(vertical: 22),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500, width: 2),
                  borderRadius: pw.BorderRadius.circular(16),
                ),
                child: pw.Text(w, style: pw.TextStyle(font: bold, fontSize: 44)),
              ),
          ],
        ),
      ],
      footer: (_) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('ReadAloud Buddy',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ),
    ));
    return doc.save();
  }

  @override
  Future<void> print({
    required String title,
    required String hint,
    required List<String> words,
  }) =>
      Printing.layoutPdf(
        name: title,
        onLayout: (_) => buildPdf(title: title, hint: hint, words: words),
      );
}

final trickyWordsPrinterProvider =
    Provider<TrickyWordsPrinter>((ref) => const PdfTrickyWordsPrinter());
