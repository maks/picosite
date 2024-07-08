import 'dart:io';
import 'package:picosite/cli.dart';
import 'package:picosite/config.dart';
import 'package:picosite/content.dart';
import 'package:picosite/previewserver.dart';

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

var config = PicositeConfig(
  outputPath: "output",
  sitePath: "site",
  includesPath: '',
  preview: false,
);

void main(List<String> arguments) async {
  config = handleArgs(arguments, config);
  config = config.copyWith(includesPath: p.join(config.sitePath, 'includes'));
  print('site dir: ${config.sitePath} output:${config.outputPath}');

  final outputDir = Directory(config.outputPath);
  outputDir.createSync(recursive: true);

  final siteDir = Directory(config.sitePath);
  if (!siteDir.existsSync()) {
    print("site directory missing!");
    exit(1);
  }

  final siteDirFiles = siteDir.listSync();
  for (final f in siteDirFiles) {
    await processFile(f, config.outputPath, config.includesPath);
  }

  copyStatic(p.join(config.sitePath, "static"), config.outputPath);

  if (config.preview) {
    final watcher = DirectoryWatcher(siteDir.path);
    watcher.events.listen((event) {
      print("WATCH event:$event");
      processFile(File(event.path), config.outputPath, config.includesPath);
    });

    final p = PreviewServer("output");
    await p.start();
  }
}

