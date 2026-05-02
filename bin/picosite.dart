import 'dart:io';
import 'package:picosite/cli.dart';
import 'package:picosite/config.dart';
import 'package:picosite/content.dart';
import 'package:picosite/pdfbuilder.dart';
import 'package:picosite/previewserver.dart';
import 'package:yaml/yaml.dart' as y;

import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

var config = PicositeConfig(
  outputPath: "output",
  sitePath: "site",
  includesPath: 'includes',
  assetsPath: 'assets',
  templatesPath: 'templates',
  dataPath: 'data',
  listingsPath: '_listings',
  preview: false,
  pdf: "pdf.yml",
);

void main(List<String> arguments) async {
  print(""); // blank line to separate output from cmd line
  config = handleArgs(arguments, config);
  print(
      'site dir: ${config.sitePath} includes dir: ${config.includesPath} assets dir: ${config.assetsPath}'
      ' templates:${config.templatesPath} output:${config.outputPath}'
      ' data:${config.dataPath} listings:${config.listingsPath}');

  final outputDir = Directory(config.outputPath);
  outputDir.createSync(recursive: true);

  config = config.copyWith(
    includesPath: p.join(config.sitePath, config.includesPath),
    assetsPath: p.join(config.sitePath, config.assetsPath),
    templatesPath: p.join(config.sitePath, config.templatesPath),
    dataPath: p.join(config.sitePath, config.dataPath),
    listingsPath: p.join(Directory.current.path, config.listingsPath),
  );

  final siteDir = Directory(config.sitePath);
  if (!siteDir.existsSync()) {
    print("site directory missing!");
    exit(1);
  }

  // Load data files and listings before processing pages
  final dataFiles = loadAllDataFiles(config.dataPath);
  final listings = loadAllListings(config.listingsPath);

  Map? pdfConfig;
  if (!config.preview && config.pdf.isNotEmpty) {
    final pdfFile = File(config.pdf);
    if (!pdfFile.existsSync()) {
      print(
          "PDF Config file missing:${pdfFile.path} CWD:${Directory.current.path}");
      exit(1);
    }

    final pdfYaml = pdfFile.readAsStringSync();
    pdfConfig = y.loadYaml(pdfYaml);
  }

  final pdfBuilder =
      (!config.preview && pdfConfig != null) ? Pdfbuilder("output.pdf") : null;

  await processAllFiles(siteDir, config, pdfBuilder,
      dataFiles: dataFiles, listings: listings);

  await copyStatic(config.assetsPath, config.outputPath);

  if (config.preview) {
    final watcher = DirectoryWatcher(siteDir.path);
    final includesWatcher = DirectoryWatcher(config.includesPath);
    watcher.events.listen((event) {
      print("WATCH event:$event");
      processFile(File(event.path), config.outputPath, config.includesPath,
          config.templatesPath, null,
          dataFiles: dataFiles, listings: listings);
    });
    includesWatcher.events.listen((event) async {
      print("INC WATCH event:$event");
      // don't know which files use this particular partial so reprocess all
      final newDataFiles = loadAllDataFiles(config.dataPath);
      final newListings = loadAllListings(config.listingsPath);
      await processAllFiles(siteDir, config, null,
          dataFiles: newDataFiles, listings: newListings);
    });

    final p = PreviewServer("output");
    await p.start();
  }

  if (pdfBuilder != null) {
    final pdfPagesRaw = pdfConfig!["pages"];
    final pdfPages = (pdfPagesRaw is List) ? pdfPagesRaw.cast<String>() : <String>[];
    print("pdfpages: ${pdfPages.length}");

    await pdfBuilder.createPDF(
      assetspath: config.assetsPath,
      pages: pdfPages,
      documentTitle: pdfConfig["title"],
      documentAuthor: pdfConfig["author"],
      styles: pdfConfig["styles"],
      tocPagePosition: pdfConfig["tocPagePosition"],
    );
  }
}

Future<void> processAllFiles(Directory siteDir, PicositeConfig config,
    Pdfbuilder? pdfBuilder,
    {Map? dataFiles = const {}, Map? listings = const {}}) async {
  final siteDirFiles = Directory(p.joinAll([siteDir.path, 'pages'])).listSync();
  siteDirFiles.sort(sortByName);
  for (final f in siteDirFiles) {
    await processFile(f, config.outputPath, config.includesPath,
        config.templatesPath, pdfBuilder,
        dataFiles: dataFiles, listings: listings);
  }
}

// sort filesystementities by name
int sortByName(FileSystemEntity a, FileSystemEntity b) {
  return p
      .basenameWithoutExtension(a.path)
      .compareTo(p.basenameWithoutExtension(b.path));
}
