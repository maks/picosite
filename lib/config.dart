class PicositeConfig {
  final String sitePath;
  final String outputPath;
  final bool preview;

  PicositeConfig({
    required this.sitePath,
    required this.outputPath,
    required this.preview,
  });

  PicositeConfig copyWith(
      {String? sitePath, String? outputPath, bool? preview}) {
    return PicositeConfig(
      sitePath: sitePath ?? this.sitePath,
      outputPath: outputPath ?? this.outputPath,
      preview: preview ?? this.preview,
    );
  }
}
