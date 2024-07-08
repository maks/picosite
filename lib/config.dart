class PicositeConfig {
  final String sitePath;
  final String outputPath;
  final String includesPath;
  final bool preview;

  PicositeConfig({
    required this.sitePath,
    required this.outputPath,
    required this.preview,
    required this.includesPath,
  });

  PicositeConfig copyWith(
      {
    String? sitePath,
    String? outputPath,
    String? includesPath,
    bool? preview,
  }) {
    return PicositeConfig(
      sitePath: sitePath ?? this.sitePath,
      outputPath: outputPath ?? this.outputPath,
      includesPath: includesPath ?? this.includesPath,
      preview: preview ?? this.preview,
    );
  }
}
