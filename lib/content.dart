import 'dart:io';
import 'package:io/io.dart';
import 'package:markdown/markdown.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import "package:markdown/markdown.dart" as m;
import 'package:yaml/yaml.dart' as y;

Future<void> processFile(final FileSystemEntity f, final String outputPath,
    final String includesPath, String templatesPath) async {
  final name = p.basename(f.path);
  print("found input file: $name");
  if (p.extension(f.path).toLowerCase() == '.md') {
    print("processing: $name");
    final markdown = (f as File).readAsStringSync();
    final title = p.basenameWithoutExtension(f.path);
    final html = await processMarkdown(
      markdown,
      title,
      includesPath,
      templatesPath,
    );

    final outputFile = File(p.join(outputPath, "$title.html"));
    outputFile.writeAsStringSync(html);
    print("wrote output to: $outputPath");
  }
}

Future<String> processMarkdown(final String markdownDoc, final String title,
    final String partialsPath, final String templatesPath) async {
  final mdTitlePattern = RegExp("^# (.*)");
  Map frontMatter = {};
  String markdownBody = "";

  // Regular expression to match the YAML front matter
  final regex = RegExp(r'^---\n([\s\S]*?)\n---\n', multiLine: true);

  final frontmatterMatch = regex.firstMatch(markdownDoc);
  if (frontmatterMatch != null) {
    // Extract YAML front matter
    final yamlFrontMatter = frontmatterMatch.group(1);
    if (yamlFrontMatter == null) {
      throw Exception('No YAML front matter found.');
    }
    // Extract the remaining markdown content
    markdownBody = markdownDoc.replaceFirst(regex, '');
    print('YAML Front Matter:\n$yamlFrontMatter');
    // print('\nMarkdown Content:\n$markdownWithoutFrontMatter');
    frontMatter = y.loadYaml(yamlFrontMatter);
  } else {
    throw Exception('No YAML front matter found.');
  }

  Map docVariables = {};
  docVariables["header"] = "";
  docVariables["title"] = title;
  final match = mdTitlePattern.firstMatch(markdownBody);
  if (match != null) {
    docVariables["title"] = match[1]!;
  } else if (frontMatter["title"] != null) {
    docVariables["title"] = frontMatter["title"];
  } else {
    docVariables["header"] = "<h1>$title</h1>\n";
  }
  print("finished processing:$title");

  docVariables['body'] = m.markdownToHtml(
    markdownBody,
    inlineSyntaxes: [
      InlineHtmlSyntax(),
    ],
    blockSyntaxes: [
      TableSyntax(),
      FencedCodeBlockSyntax(),
      HeaderWithIdSyntax(),
      HorizontalRuleSyntax(),
    ],
  );

  Template? partialsFileResolver(String name) {
    final partial = File(p.join(partialsPath, name)).readAsStringSync();
    return Template(partial);
  }

  // find template to use for this page
  String templateName = frontMatter['template'] ?? '';

  print("CWD:${Directory.current.path}");

  String templateText =
      File('$templatesPath/$templateName.html').readAsStringSync();

  final template = Template(
    templateText,
    name: title,
    htmlEscapeValues: false,
    partialResolver: partialsFileResolver,
  );

  var rendered = template.renderString(docVariables);

  return rendered;
}

void copyStatic(String input, String output) async {
  return copyPath(input, output);
}
