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
    required Map styles,
    String? documentTitle,
    String? documentAuthor,
    int tocPagePosition = 0,
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

    final codeBgColor = styles['code']['background-color'];
    final showPageNumbersFromPage = styles['show-page-numbers-from'];

    int pageCount = 0;
    for (var page in pages) {
      print("pdf page: $page");
      final List<Widget> markdownwidgets = await HTMLToPdf().convert(
        _htmlContent[page] ?? '',
        tagStyle: HtmlTagStyle(
          codeBlockBackgroundColor: PdfColor.fromInt(codeBgColor),
        ),
      );

      if (tocPagePosition == pageCount) {
        _addTOCPage(pdfDocument);
      }

      pdfDocument.addPage(
        MultiPage(
          maxPages: 50,
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return markdownwidgets;
          },
          footer: (Context context) {
            if (showPageNumbersFromPage != null &&
                context.pageNumber > showPageNumbersFromPage) {
              return Container(
                alignment: Alignment.centerRight,
                margin: const EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
                child: Text(
                  '${context.pageNumber}',
                  style: Theme.of(context)
                      .defaultTextStyle
                      .copyWith(color: PdfColors.grey),
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      );
      pageCount++;
    }

    Directory.current = currentCWD;

    await pdfOutfile.writeAsBytes(await pdfDocument.save());
    print("saved pdf: $pdfOutputPath");
  }

  void _addTOCPage(Document pdfDocument) {
    // This is using forked version of the htmltopdfwidgets package
    // https://github.com/maks/htmltopdfwidgets
    pdfDocument.addPage(
      Page(
        orientation: PageOrientation.portrait,
        build: (context) {
          return Column(
            children: [
              Center(
                child: Text(
                  'Table of contents',
                  style: Theme.of(context).header0,
                ),
              ),
              SizedBox(height: 20),
              TableOfContent(),
              Spacer(),
            ],
          );
        },
      ),
    );
  }
}
