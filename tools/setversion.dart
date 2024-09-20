import 'dart:io';

void main(List<String> arguments) {
  final pubspecFile = File('pubspec.yaml');

  if (!pubspecFile.existsSync()) {
    print('pubspec.yaml file not found.');
    return;
  }
  final pubspecContent = pubspecFile.readAsStringSync();
  final versionRegex = RegExp(r'^version: (\d+\.\d+\.\d+)$', multiLine: true);
  final version = versionRegex.firstMatch(pubspecContent);

  if (version != null) {
    print('Version: ${version.group(1)}');
    final output = File("lib/version.dart");
    output.writeAsStringSync("const String version = '${version.group(1)}';");
  } else {
    print('Version not found in pubspec.yaml file.');
  }
}
