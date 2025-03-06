import 'dart:io';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

class Pdfbuilder {
  final Map<String, String> _htmlContent = {};
  final String pdfOutputPath;

  Pdfbuilder(this.pdfOutputPath);

  void addHTMLPage(String pagename, String title, String pagecontent) {
    print("ad page: $pagename");
    _htmlContent[pagename] = pagecontent;
  }

  Future<void> createPDF(String assetspath, List<String> pages) async {
    final markdownOutfile = File(pdfOutputPath);
    final markdownNewpdf = Document();

    final currentCWD = Directory.current.path;

    Directory.current = Directory(assetspath);

    print("==== BUILDING PDF ====");
    print("$pages");

    for (var page in pages) {
      print("pdf page: $page");
      final List<Widget> markdownwidgets = await HTMLToPdf().convert(
        _htmlContent[page] ?? '',
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
