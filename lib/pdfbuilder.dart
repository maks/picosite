import 'dart:io';
import 'dart:typed_data';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';

class Pdfbuilder {
  final Map<String, String> _htmlContent = {};
  final String pdfOutputPath;
  final bool verbose;

  Pdfbuilder(this.pdfOutputPath, {this.verbose = false});

  /// Load custom fonts from a map of { fontName: ttfPath }
  /// Returns { fontName: Font } and the base/default font (first entry or ttf-font-path)
  Map<String, Font> _loadCustomFonts(
    String assetsPath,
    Map? fontsConfig,
    String? singleFontPath,
    bool verbose,
  ) {
    final Map<String, Font> customFonts = {};

    // Legacy single-font support (ttf-font-path) — treated as 'body' font
    if (singleFontPath != null) {
      final fontBytes =
          File('${Directory.current.path}/$singleFontPath').readAsBytesSync();
      customFonts['body'] = Font.ttf(ByteData.sublistView(fontBytes));
    }

    // New multi-font support
    if (fontsConfig is Map) {
      for (final entry in fontsConfig.entries) {
        final fontName = entry.key.toString();
        final ttfPath = entry.value.toString();
        try {
          final fontBytes =
              File('${Directory.current.path}/$ttfPath').readAsBytesSync();
          customFonts[fontName] = Font.ttf(ByteData.sublistView(fontBytes));
          if (verbose) print('  loaded font: $fontName -> $ttfPath');
        } catch (e) {
          if (verbose) print('  WARNING: could not load font $fontName from $ttfPath: $e');
        }
      }
    }

    return customFonts;
  }

  /// Get the base/default font for body text
  Font? _getBaseFont(Map<String, Font> customFonts) {
    // Prefer 'body' font if specified, otherwise use first available font,
    // or null (pdf library default serif)
    return customFonts['body'] ??
        (customFonts.isNotEmpty ? customFonts.values.first : null);
  }

  void addHTMLPage(String pagename, String title, String pagecontent) {
    if (verbose) print("ad page: $pagename");
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

    final assetsDir = Directory(assetspath).absolute;
    if (!assetsDir.existsSync()) {
      throw Exception('Assets directory not found: ${assetsDir.path}');
    }
    final savedCWD = Directory.current.path;
    Directory.current = assetsDir;

    if (verbose) {
      print("==== BUILDING PDF ====");
      print("Pages List: $pages");
    } else {
      print("==== BUILDING PDF ====");
    }

    final Map? codeStyle = styles['code'] as Map?;
    final int codeBgColor = (codeStyle?['background-color'] as dynamic?)?.toInt() ?? 0xffffff;
    final int? showPageNumbersFromPage = (styles['show-page-numbers-from'] as dynamic?)?.toInt();
    final String? ttfFontPath = styles['ttf-font-path'] as String?;
    final Map? rawPdfStyles = styles['pdf'] as Map?;
    final Map pdfStyles = rawPdfStyles ?? <String, dynamic>{};

    // Load all custom fonts (legacy single-font + new multi-font config)
    final Map<String, Font> customFonts = _loadCustomFonts(
      assetspath,
      styles['fonts'] as Map?,
      ttfFontPath,
      verbose,
    );
    final Font? baseFont = _getBaseFont(customFonts);
    final String? headingFontName = customFonts.containsKey('heading') ? 'heading' : null;
    final String? codeFontName = customFonts.containsKey('code') ? 'code' : null;
    final String? codeBoldFontName = customFonts.containsKey('code-bold') ? 'code-bold' : null;

    if (customFonts.isNotEmpty && verbose) {
      print('==== MULTI-FONT PDF CONFIGURATION ====');
      final baseName = baseFont != null
          ? customFonts.entries.firstWhere(
              (e) => e.value == baseFont,
              orElse: () => MapEntry('default', Font.ttf(Uint8List(0).buffer.asByteData())),
            ).key
          : 'pdf default';
      print('Base font: $baseName');
      if (headingFontName != null) print('Heading font: $headingFontName');
      if (codeFontName != null) print('Code font: $codeFontName');
    }

    int pageCount = 0;
    for (var page in pages) {
      if (verbose) print("converting HTML to PDF page: $page");
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

      // Build heading TextStyle with optional named font
      final Font? h1Font = headingFontName != null ? customFonts[headingFontName] : null;
      final TextStyle h1TextStyle = TextStyle(
        fontSize: h1FontSize,
        fontWeight: h1FontWeight ?? FontWeight.bold,
        color: h1Color,
        font: h1Font,
      );

      // Build inline code TextStyle with optional named font
      final Font? codeFont = codeFontName != null ? customFonts[codeFontName] : null;
      TextStyle? inlineCodeTextStyle;
      if (inlineCodeTextColor != null) {
        inlineCodeTextStyle = TextStyle(
          color: inlineCodeTextColor,
          font: codeFont,
        );
      }

      final tagStyle = HtmlTagStyle(
        codeBlockBackgroundColor: PdfColor.fromInt(codeBgColor),
        paragraphMargin: EdgeInsets.only(bottom: paragraphMarginBottom),
        listMargin:
            EdgeInsets.only(left: listMarginLeft, bottom: listMarginBottom),
        headingMargins: {
          1: EdgeInsets.only(bottom: h1MarginBottom),
        },
        codeStyle: inlineCodeTextStyle,
        inlineCodeBackgroundColor: inlineCodeBackgroundColor,
        inlineCodeBorderColor: inlineCodeBorderColor,
        inlineCodeBorderWidth: inlineCodeBorderWidth ?? 1,
        inlineCodePadding: inlineCodePadding ?? 2,
        inlineClassStyles: inlineClassStyles,
        blockClassStyles: blockClassStyles,
        h1Style: h1TextStyle,
      );

      // Pass custom fonts to HTMLToPdf for CSS font-family resolution
      final htmlToPdf = customFonts.isNotEmpty
          ? HTMLToPdf(customFonts: customFonts)
          : HTMLToPdf();

      final List<Widget> markdownwidgets = await htmlToPdf.convert(
        _htmlContent[page] ?? '',
        useNewEngine: true,
        tagStyle: tagStyle,
      );

      if (tocPagePosition == pageCount) {
        _addTOCPage(pdfDocument, baseFont: baseFont);
      }

      pdfDocument.addPage(
        MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: baseFont != null
              ? ThemeData.withFont(
                  base: baseFont,
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
                      .copyWith(color: PdfColors.grey, font: baseFont),
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

    Directory.current = savedCWD;

    await pdfOutfile.writeAsBytes(await pdfDocument.save(), flush: true);
    if (verbose) print("saved pdf: $pdfOutputPath");
  }

  void _addTOCPage(
    Document pdfDocument, {
    Font? baseFont,
  }) {
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
                  style: Theme.of(context).header0.copyWith(
                    font: baseFont,
                  ),
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
        paddingHorizontal: _toDouble(values['padding_horizontal']),
        paddingVertical: _toDouble(values['padding_vertical']),
        borderRadius: _toDouble(values['border_radius']),
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
