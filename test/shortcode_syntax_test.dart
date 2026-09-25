import 'package:markdown/markdown.dart';
import 'package:picosite/shortcode_syntax.dart';
import 'package:test/test.dart';

String parseShortcodes(
  String markdown, {
  String sourceName = 'test.md',
  int sourceLineOffset = 0,
}) {
  return markdownToHtml(
    markdown,
    blockSyntaxes: [
      ShortcodeSyntax(
        sourceName: sourceName,
        sourceLineOffset: sourceLineOffset,
      ),
    ],
  );
}

void main() {
  group('ShortcodeSyntax', () {
    test('reports an unclosed multiline shortcode with source and line', () {
      const markdown = '''
{% callout type=note %}
Note text.
{
  % endcallout %
}
''';

      expect(
        () => parseShortcodes(markdown, sourceLineOffset: 1),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains(
              'test.md:2: unclosed {% callout %}; expected {% endcallout %}',
            ),
          ),
        ),
      );
    });

    test('parses a properly closed multiline shortcode', () {
      const markdown = '''
{% callout type=note %}
Note text.
{% endcallout %}
''';

      expect(
        parseShortcodes(markdown),
        contains('<div class="picosite-shortcode"'),
      );
    });
  });
}
