import 'dart:io';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

class Pdfbuilder {
  final List<String> _htmlContent = [];
  final String pdfOutputPath;

  Pdfbuilder(this.pdfOutputPath);

  void addHTMLPage(String page) {
    _htmlContent.add(page);
  }

  Future<void> createPDF(String assetspath) async {
    final markdownOutfile = File(pdfOutputPath);
    final markdownNewpdf = Document();

    final currentCWD = Directory.current.path;

    Directory.current = Directory(assetspath);

    // for (var md in _markDownContent) {
    for (var html in _htmlContent) {
      final List<Widget> markdownwidgets = await HTMLToPdf().convert(
        html,
      );

      markdownNewpdf.addPage(
        MultiPage(
          maxPages: 50,
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return markdownwidgets;
          },
        ),
      );
    }

    Directory.current = currentCWD;

    await markdownOutfile.writeAsBytes(await markdownNewpdf.save());
    print("saved pdf: $pdfOutputPath");
  }
}
