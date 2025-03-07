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

  Future<void> createPDF({
    required String assetspath,
    required List<String> pages,
    String? documentTitle,
    String? documentAuthor,
    required Map styles,
  }) async {
    final pdfOutfile = File(pdfOutputPath);

    final pdfDocument = Document(
      title: documentTitle,
      author: documentAuthor,
      producer: 'picosite',
      pageMode: PdfPageMode.outlines,
    );

    final currentCWD = Directory.current.path;

    Directory.current = Directory(assetspath);

    print("==== BUILDING PDF ====");
    print("$pages");

    // TODO: TOC use needs to wait for htmltopdfwidgets package support for
    // converting html heading elements to PDF Header widgets

    // pdfDocument.addPage(
    //   Page(
    //     orientation: PageOrientation.portrait,
    //     build: (context) {
    //       return Column(
    //         children: [
    //           Center(
    //             child: Text(
    //               'Table of contents',
    //               style: Theme.of(context).header0,
    //             ),
    //           ),
    //           SizedBox(height: 20),
    //           TableOfContent(),
    //           Spacer(),
    //         ],
    //       );
    //     },
    //   ),
    // );

    final codeBgColor = styles['code']['background-color'];

    for (var page in pages) {
      print("pdf page: $page");
      final List<Widget> markdownwidgets = await HTMLToPdf().convert(
        _htmlContent[page] ?? '',
        tagStyle: HtmlTagStyle(
          codeBlockBackgroundColor: PdfColor.fromInt(codeBgColor),
        ),
      );

      pdfDocument.addPage(
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

    await pdfOutfile.writeAsBytes(await pdfDocument.save());
    print("saved pdf: $pdfOutputPath");
  }
}
