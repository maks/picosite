import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:picosite/cli.dart';
import 'package:picosite/config.dart';
import 'package:picosite/content.dart';
import 'package:picosite/previewserver.dart';


var config = PicositeConfig(
  outputPath: "output",
  sitePath: "site",
  preview: false,
);

void main(List<String> arguments) async {
  config = handleArgs(arguments, config);
  print("site dir: ${config.sitePath} output:${config.outputPath}");

  final outputDir = Directory(config.outputPath);
  outputDir.createSync(recursive: true);

  final siteDir = Directory(config.sitePath);
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

      final outputFile = File(p.join(config.outputPath, "$title.html"));
      outputFile.writeAsStringSync(html);
      print("wrote output to: ${config.outputPath}");
    }
  }

  if (config.preview) {
    final p = PreviewServer("output");
    await p.start();
  }
}

