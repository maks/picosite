import 'dart:io';
import 'package:path/path.dart' as p;
import "package:markdown/markdown.dart" as m;
import 'package:yaml/yaml.dart' as y;

void processFile(FileSystemEntity f, String outputPath) {
  final name = p.basename(f.path);
  print("found input file: $name");
  if (p.extension(f.path).toLowerCase() == '.md') {
    print("processing: $name");
    final markdown = (f as File).readAsStringSync();
    final title = p.basenameWithoutExtension(f.path);
    final html = processMarkdown(markdown, title);

    final outputFile = File(p.join(outputPath, "$title.html"));
    outputFile.writeAsStringSync(html);
    print("wrote output to: $outputPath");
  }
}

String processMarkdown(String doc, String title) {
  final mdTitlePattern = RegExp("^# (.*)");
  String body = "";

  // try to process any yaml front matter
  var sections = doc.split("---");
  if (sections.length != 3 && sections.length != 2) {
    // try again with 4 dashes
    sections = doc.split("----");
  }
  Map? frontMatter;
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

  String header = "";
  final match = mdTitlePattern.firstMatch(body);
  if (match != null) {
    title = match[1]!;
  } else if (frontMatter?["title"] != null) {
    title = frontMatter!["title"];
  } else {
    header = "<h1>$title</h1>\n";
  }

  print("finished processing:$title");

  body = body
      .replaceAll("{{title}}", title)
      .replaceAll("{{header}}", header)
      .replaceAll("{{body}}", body);

  return m.markdownToHtml(body);
}
