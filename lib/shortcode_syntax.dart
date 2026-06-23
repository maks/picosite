import 'dart:convert';
import 'package:markdown/markdown.dart';

/// Parses generic `{% name key=value %}` blocks and outputs a minimal wrapper element.
///
/// The actual HTML rendering is handled by post-processing in [processMarkdown]
/// using a project-level Mustache template named `<name>.html` in the partials directory.
///
/// Supports two forms:
///
/// **Multi-line:**
/// ```
/// {% my_shortcode type=note size=large %}
/// This is the inner markdown content.
/// {% endmy_shortcode %}
/// ```
///
/// **Single-line:**
/// ```
/// {% button url=https://example.com | Click Here %}
/// ```
///
/// Any `key=value` attributes are automatically extracted, parsed, and injected
/// as JSON into a `data-shortcode-attrs` attribute on the generated wrapper element.
class ShortcodeSyntax extends BlockSyntax {
  /// Opening tag pattern: {% name key=val | text %}
  static final _openPattern = RegExp(
    r'^\{%\s*([a-zA-Z0-9_-]+)(?:\s+([^|%]*?))?(?:\|\s*(.*?)\s*)?%\}$',
  );

  /// Closing tag pattern: {% endname %}
  static final _closePattern = RegExp(
    r'^\{%\s*end([a-zA-Z0-9_-]+)\s*%\}$',
  );

  const ShortcodeSyntax();

  @override
  RegExp get pattern => _openPattern;

  @override
  Node parse(BlockParser parser) {
    final match = _openPattern.firstMatch(parser.current.content)!;
    final name = match.group(1)!;
    final attrsStr = match.group(2)?.trim() ?? '';
    final inlineText = match.group(3);

    // Parse attributes
    final Map<String, String> attrs = {};
    if (attrsStr.isNotEmpty) {
      final parts = attrsStr.split(RegExp(r'\s+'));
      for (final p in parts) {
        final kv = p.split('=');
        if (kv.length == 2) {
          attrs[kv[0]] = kv[1];
        } else if (kv.length == 1) {
          attrs[kv[0]] = 'true';
        }
      }
    }

    if (inlineText != null && inlineText.trim().isNotEmpty) {
      parser.advance();
      return _buildShortcode(name, attrs, inlineText.trim());
    }

    // Multi-line: collect lines until closing tag matches the shortcode name
    parser.advance();
    final lines = <String>[];
    while (!parser.isDone) {
      final currentLine = parser.current.content;
      final closeMatch = _closePattern.firstMatch(currentLine);
      if (closeMatch != null && closeMatch.group(1) == name) {
        parser.advance();
        break;
      }
      lines.add(currentLine);
      parser.advance();
    }

    final text = lines.join('\n').trim();
    return _buildShortcode(name, attrs, text);
  }

  Element _buildShortcode(String name, Map<String, String> attrs, String text) {
    // Parse inner text with inline-only syntaxes (bold, italic, links, code)
    final doc = Document(withDefaultBlockSyntaxes: false);
    final inlineNodes = doc.parseInline(text);

    // Output a minimal wrapper. The data-shortcode-* attributes are used by
    // post-processing to apply the project's shortcode template.
    final div = Element('div', inlineNodes);
    div.attributes['class'] = 'picosite-shortcode';
    div.attributes['data-shortcode-name'] = name;
    div.attributes['data-shortcode-attrs'] = base64Encode(utf8.encode(jsonEncode(attrs)));

    return div;
  }
}