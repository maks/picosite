import 'dart:io';
import 'package:io/io.dart';
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

Future<String> processMarkdown(final String doc, final String title,
    final String partialsPath, final String templatesPath) async {
  final mdTitlePattern = RegExp("^# (.*)");
  String body = "";

  // try to process any yaml front matter
  var sections = doc.split("---");
  if (sections.length != 3 && sections.length != 2) {
    // try again with 4 dashes
    sections = doc.split("----");
  }
  Map frontMatter = {};
  // front matter only delimited by trailing dashes line
  if (sections.length == 2) {
    frontMatter = y.loadYaml(sections[0]);
    body = sections[1];
  } // front matter  delimited by leading and trailing dashes line
  else if (sections.length == 3) {
    frontMatter = y.loadYaml(sections[1]);
    body = sections[2];
  } else {
    print("no YAML frontmatter");
  }

  Map docVariables = {};
  docVariables["header"] = "";
  docVariables["title"] = title;
  final match = mdTitlePattern.firstMatch(body);
  if (match != null) {
    docVariables["title"] = match[1]!;
  } else if (frontMatter["title"] != null) {
    docVariables["title"] = frontMatter["title"];
  } else {
    docVariables["header"] = "<h1>$title</h1>\n";
  }
  print("finished processing:$title");

  docVariables['body'] = m.markdownToHtml(body);

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
