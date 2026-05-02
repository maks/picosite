import 'dart:convert';
import 'dart:io';
import 'package:io/io.dart';
import 'package:markdown/markdown.dart';
import 'package:mustache_template/mustache.dart';
import 'package:path/path.dart' as p;
import "package:markdown/markdown.dart" as m;
import 'package:yaml/yaml.dart' as y;

import 'pdfbuilder.dart';

Future<void> processFile(
    final FileSystemEntity f,
    final String outputPath,
    final String includesPath,
    String templatesPath,
    Pdfbuilder? pdfBuilder,
    {Map? dataFiles,
    Map? listings}) async {
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
      name,
      pdfBuilder,
      dataFiles: dataFiles,
      listings: listings,
    );

    final outputFile = File(p.join(outputPath, "$title.html"));
    outputFile.writeAsStringSync(html);
    print("wrote output to: $outputPath");
  }
}

Future<String> processMarkdown(
    final String markdownDoc,
    final String title,
    final String partialsPath,
    final String templatesPath,
    final String filename,
    final Pdfbuilder? pdfBuilder, {
    Map? dataFiles,
    Map? listings,
  }) async {
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

  // Pre-format date values if present in frontmatter
  if (frontMatter['date'] != null) {
    try {
      final dateStr = frontMatter['date'].toString();
      final date = DateTime.parse(dateStr);
      docVariables['date_iso'] = date.toIso8601String().split('T')[0];
      final months = [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      docVariables['date_long'] = '${months[date.month]} ${date.day}, ${date.year}';
    } catch (e) {
      // If date parsing fails, just use the raw value
    }
  }

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

  // Add _data access for JSON data files (e.g., {{_data.talks}})
  docVariables['_data'] = dataFiles ?? {};

  // Add _lists access for content listings (e.g., {{#_lists.blog_posts}})
  docVariables['_lists'] = listings ?? {};

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

  if (pdfBuilder != null) {
    final pdfTemplateName = '$templatesPath/${templateName}_pdf.html';
    final pdfTemplateFile = File(pdfTemplateName);
    if (pdfTemplateFile.existsSync()) {
      print("PDF template: $pdfTemplateName");
      String templateUrlText = pdfTemplateFile.readAsStringSync();

      final pdftemplate = Template(
        templateUrlText,
        name: title,
        htmlEscapeValues: false,
        partialResolver: partialsFileResolver,
      );

      final rendered = pdftemplate.renderString(docVariables);
      pdfBuilder.addHTMLPage(filename, docVariables["title"], rendered);
    } else {
      print("PDF template not found, skipping: $pdfTemplateName");
    }
  }

  final rendered = template.renderString(docVariables);
  return rendered;
}

Future<void> copyStatic(String input, String output) async {
  return copyPath(input, output);
}

// ============ Helper functions ============

/// Loads all JSON data files from the data directory
Map loadAllDataFiles(String dataPath) {
  final Map dataFiles = {};
  final dataDir = Directory(dataPath);
  if (!dataDir.existsSync()) {
    print("Data directory not found: $dataPath");
    return dataFiles;
  }
  
  final files = dataDir.listSync();
  for (final file in files) {
    if (file is File && file.path.endsWith('.json')) {
      final name = p.basenameWithoutExtension(file.path);
      final content = file.readAsStringSync();
      try {
        final data = jsonDecode(content);
        dataFiles[name] = data;
        print('Loaded data file: $name');
      } catch (e) {
        print('Error loading $name: $e');
      }
    }
  }
  return dataFiles;
}

/// Loads all listings from the _listings directory
Map loadAllListings(String listingsPath) {
  final Map listings = {};
  final listingsDir = Directory(listingsPath);
  if (!listingsDir.existsSync()) {
    print("Listings directory not found: $listingsPath");
    return listings;
  }
  
  for (final file in listingsDir.listSync()) {
    if (file is File && file.path.endsWith('.yaml')) {
      final name = p.basenameWithoutExtension(file.path);
      final content = file.readAsStringSync();
      final config = y.loadYaml(content);
      
      final path = config['path'];
      final filter = config['filter'] ?? '*.md';
      final sortBy = config['sort_by'];
      
      final items = _loadListingItems(path, filter, sortBy);
      listings[name] = items;
      print('Loaded listing: $name with ${items.length} items');
    }
  }
  return listings;
}

/// Loads items from a listing based on path and filter
List<Map> _loadListingItems(String basePath, String filter, String? sortBy) {
  final List<Map> items = [];
  final baseDir = Directory(basePath);
  if (!baseDir.existsSync()) return items;
  
  final files = baseDir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.md')) {
      // Check if filename matches filter pattern (simple wildcard)
      final filename = p.basename(file.path);
      if (!_matchesFilter(filename, filter)) continue;
      
      final content = file.readAsStringSync();
      final frontmatter = _extractFrontmatter(content);
      if (frontmatter != null) {
        // Create mutable copy to avoid modifying unmodifiable maps
        final item = Map.from(frontmatter);
        item['path'] = file.path;
        
        // Pre-format dates for listing items
        if (item['date'] != null) {
          try {
            final dateStr = item['date'].toString();
            final date = DateTime.parse(dateStr);
            item['date_iso'] = date.toIso8601String().split('T')[0];
            final months = [
              '', 'January', 'February', 'March', 'April', 'May', 'June',
              'July', 'August', 'September', 'October', 'November', 'December'
            ];
            item['date_long'] = '${months[date.month]} ${date.day}, ${date.year}';
          } catch (e) {
            // If date parsing fails, just use the raw value
          }
        }
        
        items.add(item);
      }
    }
  }
  
  // Sort items if sortBy is specified
  if (sortBy != null) {
    final parts = sortBy.split(' ');
    final field = parts[0];
    final reverse = parts.length > 1 && parts[1].toUpperCase() == 'DESC';
    
    items.sort((a, b) {
      final va = a[field];
      final vb = b[field];
      if (va is Comparable && vb is Comparable) {
        return va.compareTo(vb) * (reverse ? -1 : 1);
      }
      return 0;
    });
  }
  
  return items;
}

/// Checks if a filename matches a filter pattern (supports * wildcard)
bool _matchesFilter(String filename, String filter) {
  if (filter == '*') return true;
  if (filter == filename) return true;
  
  // Convert glob pattern to regex
  final regexPattern = filter
      .replaceAll('.', r'\.')
      .replaceAll('*', r'.*');
  final regex = RegExp('^$regexPattern\$');
  return regex.hasMatch(filename);
}

/// Extracts YAML frontmatter from markdown content
Map? _extractFrontmatter(String markdown) {
  final regex = RegExp(r'^---\n([\s\S]*?)\n---\n', multiLine: true);
  final match = regex.firstMatch(markdown);
  if (match == null) return null;
  
  final yaml = match.group(1);
  if (yaml == null) return null;
  
  return y.loadYaml(yaml);
}
