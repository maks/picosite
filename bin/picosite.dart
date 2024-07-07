import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:markdown/markdown.dart' as m;
import 'package:yaml/yaml.dart' as y;
import 'previewserver.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addOption(
      'site',
      abbr: 's',
      help: 'Directory containing site source files.',
    )
    ..addFlag(
      'preview',
      abbr: 'p',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart picosite.dart <flags> [arguments]');
  print(argParser.usage);
}

String sitePath = ".";
String outputPath = "output";
bool _preview = false;

void main(List<String> arguments) async {
  handleArgs(arguments);
  print("site dir: $sitePath");

  final outputDir = Directory(outputPath);
  outputDir.createSync(recursive: true);

  final siteDir = Directory(sitePath);
  if (!siteDir.existsSync()) {
    print("site directory missing!");
    exit(1);
  }

  final siteDirFiles = siteDir.listSync();
  for (final f in siteDirFiles) {
    final name = p.basename(f.path);
    print("found: $name");
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

  if (_preview) {
    final p = PreviewServer("output");
    await p.start();
  }
}

void handleArgs(arguments) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.wasParsed('preview')) {
      _preview = true;
    }

    if (results.wasParsed('site')) {
      sitePath = results.option("site")!;
    }

    if (results.wasParsed('help')) {
      printUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      print('picosite version: $version');
      return;
    }
    if (results.wasParsed('verbose')) {
      verbose = true;
    }

    // Act on the arguments provided.
    print('Positional arguments: ${results.rest}');
    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
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
