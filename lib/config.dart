class PicositeConfig {
  final String sitePath;
  final String outputPath;
  final String includesPath;
  final String assetsPath;
  final String templatesPath;
  final String dataPath;
  final String listingsPath;
  final bool preview;
  final String pdf;

  PicositeConfig({
    required this.sitePath,
    required this.outputPath,
    required this.preview,
    required this.includesPath,
    required this.assetsPath,
    required this.templatesPath,
    required this.dataPath,
    required this.listingsPath,
    required this.pdf,
  });

  PicositeConfig copyWith({
    String? sitePath,
    String? outputPath,
    String? includesPath,
    String? assetsPath,
    String? templatesPath,
    String? dataPath,
    String? listingsPath,
    bool? preview,
    String? pdf,
  }) {
    return PicositeConfig(
      sitePath: sitePath ?? this.sitePath,
      outputPath: outputPath ?? this.outputPath,
      includesPath: includesPath ?? this.includesPath,
      assetsPath: assetsPath ?? this.assetsPath,
      templatesPath: templatesPath ?? this.templatesPath,
      dataPath: dataPath ?? this.dataPath,
      listingsPath: listingsPath ?? this.listingsPath,
      preview: preview ?? this.preview,
      pdf: pdf ?? this.pdf,
    );
  }
}
