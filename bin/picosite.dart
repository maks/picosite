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
  includesPath: 'includes',
  assetsPath: 'assets',
  preview: false,
);

void main(List<String> arguments) async {
  config = handleArgs(arguments, config);
  print('site dir: ${config.sitePath} includes dir: ${config.includesPath} assets dir: ${config.assetsPath}' 
  ' output:${config.outputPath}');

  final outputDir = Directory(config.outputPath);
  outputDir.createSync(recursive: true);

  final siteDir = Directory(config.sitePath);
  if (!siteDir.existsSync()) {
    print("site directory missing!");
    exit(1);
  }

  await processAllFiles(siteDir, config);
  
  copyStatic(config.sitePath, config.outputPath);

  if (config.preview) {
    final watcher = DirectoryWatcher(siteDir.path);
    final includesWatcher = DirectoryWatcher(config.includesPath);
    watcher.events.listen((event) {
      print("WATCH event:$event");
      processFile(File(event.path), config.outputPath, config.includesPath);
    });
    includesWatcher.events.listen((event) async {
      print("INC WATCH event:$event");
      // dont know which files use this particular partial so reprocess all
      await processAllFiles(siteDir, config);
    });

    final p = PreviewServer("output");
    await p.start();
  }
}

Future<void> processAllFiles(Directory siteDir, PicositeConfig config) async {
  final siteDirFiles = siteDir.listSync();
  for (final f in siteDirFiles) {
    await processFile(f, config.outputPath, config.includesPath);
  }	
}

