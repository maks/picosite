import 'dart:io';
import 'dart:typed_data';

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
    int? tocPagePosition = 0,
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
    print("Pages List: $pages");

    final Map? codeStyle = styles['code'] as Map?;
    final int codeBgColor = (codeStyle?['background-color'] as dynamic?)?.toInt() ?? 0xffffff;
    final int? showPageNumbersFromPage = (styles['show-page-numbers-from'] as dynamic?)?.toInt();
    final String? ttfFontPath = styles['ttf-font-path'] as String?;
    final Map? rawPdfStyles = styles['pdf'] as Map?;
    final Map pdfStyles = rawPdfStyles ?? <String, dynamic>{};

    Font? customFont;
    if (ttfFontPath != null) {
      final fontbytes =
          File('${Directory.current.path}/$ttfFontPath').readAsBytesSync();
      customFont = Font.ttf(ByteData.sublistView(fontbytes));
    }

    int pageCount = 0;
    for (var page in pages) {
      print("converting HTML to PDF page: $page");
      final paragraphMarginBottom =
          _toDouble(pdfStyles['paragraph_margin_bottom']) ?? 10;
      final listMarginLeft = _toDouble(pdfStyles['list_margin_left']) ?? 18;
      final listMarginBottom =
          _toDouble(pdfStyles['list_margin_bottom']) ?? 10;
      final h1MarginBottom = _toDouble(pdfStyles['h1_margin_bottom']) ?? 12;
      final h1FontSize = _toDouble(pdfStyles['h1_font_size']) ?? 22;
      final h1Color = _parsePdfColor(pdfStyles['h1_color']);
      final h1FontWeight = _parseFontWeight(pdfStyles['h1_font_weight']);
      final inlineCodeTextColor =
          _parsePdfColor(pdfStyles['inline_code_text_color']);
      final inlineCodeBackgroundColor =
          _parsePdfColor(pdfStyles['inline_code_background_color']);
      final inlineCodeBorderColor =
          _parsePdfColor(pdfStyles['inline_code_border_color']);
      final inlineCodeBorderWidth =
          _toDouble(pdfStyles['inline_code_border_width']);
      final inlineCodePadding = _toDouble(pdfStyles['inline_code_padding']);
      final inlineClassStyles = _parseInlineClassStyles(
          pdfStyles['class_styles'] is Map ? pdfStyles['class_styles'] as Map : null);
      final blockClassStyles = _parseBlockClassStyles(
          pdfStyles['block_class_styles'] is Map
              ? pdfStyles['block_class_styles'] as Map
              : null);

      final tagStyle = HtmlTagStyle(
        codeBlockBackgroundColor: PdfColor.fromInt(codeBgColor),
        paragraphMargin: EdgeInsets.only(bottom: paragraphMarginBottom),
        listMargin:
            EdgeInsets.only(left: listMarginLeft, bottom: listMarginBottom),
        headingMargins: {
          1: EdgeInsets.only(bottom: h1MarginBottom),
        },
        codeStyle: inlineCodeTextColor != null
            ? TextStyle(color: inlineCodeTextColor)
            : null,
        inlineCodeBackgroundColor: inlineCodeBackgroundColor,
        inlineCodeBorderColor: inlineCodeBorderColor,
        inlineCodeBorderWidth: inlineCodeBorderWidth ?? 1,
        inlineCodePadding: inlineCodePadding ?? 2,
        inlineClassStyles: inlineClassStyles,
        blockClassStyles: blockClassStyles,
        h1Style: TextStyle(
          fontSize: h1FontSize,
          fontWeight: h1FontWeight ?? FontWeight.bold,
          color: h1Color,
        ),
      );

      final List<Widget> markdownwidgets = await HTMLToPdf().convert(
        _htmlContent[page] ?? '',
        useNewEngine: true,
        tagStyle: tagStyle,
      );

      if (tocPagePosition == pageCount) {
        _addTOCPage(pdfDocument);
      }

      pdfDocument.addPage(
        MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: customFont != null
              ? ThemeData.withFont(
                  base: customFont,
                )
              : null,
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
                      .copyWith(color: PdfColors.grey, font: customFont),
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

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  PdfColor? _parsePdfColor(dynamic value) {
    if (value == null) return null;
    if (value is PdfColor) return value;
    if (value is int) return PdfColor.fromInt(value);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('#')) {
        return PdfColor.fromHex(trimmed);
      }
      if (trimmed.startsWith('0x') || trimmed.startsWith('0X')) {
        final parsed = int.tryParse(trimmed);
        if (parsed != null) return PdfColor.fromInt(parsed);
      }
    }
    return null;
  }

  FontWeight? _parseFontWeight(dynamic value) {
    if (value == null) return null;
    if (value is FontWeight) return value;
    if (value is num) {
      return value >= 600 ? FontWeight.bold : FontWeight.normal;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'bold' ||
          normalized == '700' ||
          normalized == '800' ||
          normalized == '900') {
        return FontWeight.bold;
      }
      if (normalized == 'normal' || normalized == '400') {
        return FontWeight.normal;
      }
    }
    return null;
  }

  Map<String, InlineTagStyle> _parseInlineClassStyles(Map? classStyles) {
    final styles = <String, InlineTagStyle>{};
    if (classStyles == null) return styles;

    for (final entry in classStyles.entries) {
      final className = entry.key?.toString();
      if (className == null || className.isEmpty) continue;
      if (entry.value is! Map) continue;
      final Map values = entry.value as Map;
      styles[className] = InlineTagStyle(
        textColor: _parsePdfColor(values['text_color']),
        backgroundColor: _parsePdfColor(values['background_color']),
        borderColor: _parsePdfColor(values['border_color']),
        borderWidth: _toDouble(values['border_width']) ?? 1,
        padding: _toDouble(values['padding']) ?? 2,
      );
    }

    return styles;
  }

  Map<String, BlockTagStyle> _parseBlockClassStyles(Map? classStyles) {
    final styles = <String, BlockTagStyle>{};
    if (classStyles == null) return styles;

    for (final entry in classStyles.entries) {
      final className = entry.key?.toString();
      if (className == null || className.isEmpty) continue;
      if (entry.value is! Map) continue;
      final Map values = entry.value as Map;
      styles[className] = BlockTagStyle(
        textColor: _parsePdfColor(values['text_color']),
        backgroundColor: _parsePdfColor(values['background_color']),
        borderColor: _parsePdfColor(values['border_color']),
        borderWidth: _toDouble(values['border_width']) ?? 1,
        padding: _toDouble(values['padding']),
        margin: _toDouble(values['margin']),
        borderRadius: _toDouble(values['border_radius']),
        fontSize: _toDouble(values['font_size']),
        fontWeight: _parseFontWeight(values['font_weight']),
        fontStyle: _parseFontStyle(values['font_style']),
      );
    }

    return styles;
  }

  FontStyle? _parseFontStyle(dynamic value) {
    if (value == null) return null;
    if (value is FontStyle) return value;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'italic') return FontStyle.italic;
      if (normalized == 'normal') return FontStyle.normal;
    }
    return null;
  }
}
