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
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Make paths absolute relative to site
  config = config.copyWith(
    includesPath: p.join(config.sitePath, config.includesPath),
    assetsPath: p.join(config.sitePath, config.assetsPath),
    templatesPath: p.join(config.sitePath, config.templatesPath),
    dataPath: p.join(config.sitePath, config.dataPath),
  );

  // Load listings from CWD (not inside site directory)
  final listingsPath = config.listingsPath;

  final siteDir = Directory(config.sitePath);
  if (!siteDir.existsSync()) {
    print("site directory missing!");
    exit(1);
  }

  // Load data files and listings before processing pages
  final dataFiles = loadAllDataFiles(config.dataPath, config.verbose);
  final listings = loadAllListings(listingsPath, config.verbose);

  Map? pdfConfig;
  if (!config.preview && config.pdf.isNotEmpty) {
    final pdfFile = File(config.pdf);
    if (pdfFile.existsSync()) {
      final pdfYaml = pdfFile.readAsStringSync();
      pdfConfig = y.loadYaml(pdfYaml);
    }
  }

  final pdfBuilder =
      (!config.preview && pdfConfig != null) ? Pdfbuilder("output.pdf", verbose: config.verbose) : null;

  final pagesDir = Directory(p.joinAll([siteDir.path, 'pages']));
  final List<FileSystemEntity> siteDirFiles = [];
  if (pagesDir.existsSync()) {
    siteDirFiles.addAll(pagesDir.listSync(recursive: true));
  }
  siteDirFiles.sort(sortByName);
  for (final f in siteDirFiles) {
    if (f is File && p.extension(f.path).toLowerCase() == '.md') {
      await processFile(f, p.join(siteDir.path, 'pages'), config.outputPath, config.includesPath,
          config.templatesPath, pdfBuilder, config.verbose,
          dataFiles: dataFiles, listings: listings);
    }
  }

  await copyStatic(config.assetsPath, config.outputPath);

  if (config.preview) {
    final watcher = DirectoryWatcher(siteDir.path);
    final includesWatcher = DirectoryWatcher(config.includesPath);
    watcher.events.listen((event) async {
      if (config.verbose) print("WATCH event:$event");
      // For now, we just process the file if it exists in our list
      await processAllFiles(siteDir, config, null,
          dataFiles: dataFiles, listings: listings);
    });
    includesWatcher.events.listen((event) async {
      if (config.verbose) print("INC WATCH event:$event");
      // don't know which files use this particular partial so reprocess all
      final newDataFiles = loadAllDataFiles(config.dataPath, config.verbose);
      final newListings = loadAllListings(config.listingsPath, config.verbose);
      await processAllFiles(siteDir, config, null,
          dataFiles: newDataFiles, listings: newListings);
    });

    final p = PreviewServer(config.outputPath);
    await p.start();
  }

  if (pdfBuilder != null) {
    final pdfPagesRaw = pdfConfig!["pages"];
    final pdfPages = (pdfPagesRaw is List) ? pdfPagesRaw.cast<String>() : <String>[];
    if (config.verbose) print("pdfpages: ${pdfPages.length}");

    await pdfBuilder.createPDF(
      assetspath: config.assetsPath,
      pages: pdfPages,
      documentTitle: (pdfConfig["title"] as String?) ?? "Manichord",
      documentAuthor: (pdfConfig["author"] as String?) ?? "Maksim Lin",
      styles: (pdfConfig["styles"] as Map?) ?? <String, dynamic>{},
      tocPagePosition: (pdfConfig["tocPagePosition"] as int?) ?? 0,
    );
  }
}

Future<void> processAllFiles(Directory siteDir, PicositeConfig config,
    Pdfbuilder? pdfBuilder,
    {Map? dataFiles = const {}, Map? listings = const {}}) async {
  final pagesDir = Directory(p.joinAll([siteDir.path, 'pages']));
  final List<FileSystemEntity> siteDirFiles = [];
  if (pagesDir.existsSync()) {
    siteDirFiles.addAll(pagesDir.listSync(recursive: true));
  }
  siteDirFiles.sort(sortByName);
  for (final f in siteDirFiles) {
    if (f is File && p.extension(f.path).toLowerCase() == '.md') {
      await processFile(f, p.join(siteDir.path, 'pages'), config.outputPath, config.includesPath,
          config.templatesPath, pdfBuilder, config.verbose,
          dataFiles: dataFiles, listings: listings);
    }
  }
}

// sort filesystementities by name
int sortByName(FileSystemEntity a, FileSystemEntity b) {
  return p
      .basenameWithoutExtension(a.path)
      .compareTo(p.basenameWithoutExtension(b.path));
}
