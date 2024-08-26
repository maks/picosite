class PicositeConfig {
  final String sitePath;
  final String outputPath;
  final String includesPath;
  final String assetsPath;
  final String templatesPath;
  final bool preview;

  PicositeConfig({
    required this.sitePath,
    required this.outputPath,
    required this.preview,
    required this.includesPath,
    required this.assetsPath,
    required this.templatesPath,
  });

  PicositeConfig copyWith({
    String? sitePath,
    String? outputPath,
    String? includesPath,
    String? assetsPath,
    String? templatesPath,
    bool? preview,
  }) {
    return PicositeConfig(
      sitePath: sitePath ?? this.sitePath,
      outputPath: outputPath ?? this.outputPath,
      includesPath: includesPath ?? this.includesPath,
      assetsPath: assetsPath ?? this.assetsPath,
      templatesPath: templatesPath ?? this.templatesPath,
      preview: preview ?? this.preview,
    );
  }
}
