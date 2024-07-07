import 'dart:io';

import 'package:args/args.dart';
import 'package:picosite/config.dart';

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

PicositeConfig handleArgs(arguments, PicositeConfig config) {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.wasParsed('preview')) {
      config = config.copyWith(preview: true);
    }

    if (results.wasParsed('site')) {
      config = config.copyWith(sitePath: results.option("site"));
    }

    if (results.wasParsed('help')) {
      printUsage(argParser);
      exit(0);
    }
    if (results.wasParsed('version')) {
      print('picosite version: $version');
      exit(0);
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
  return config;
}
