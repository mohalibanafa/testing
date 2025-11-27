class Model {
  final String name;
  final String description;
  final String? url;
  final bool isDefault;
  final bool isAsset;

  const Model({
    required this.name,
    required this.description,
    this.url,
    this.isDefault = false,
    this.isAsset = false,
  });
}
