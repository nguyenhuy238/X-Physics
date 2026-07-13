class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  final String id;
  final String name;
  final String description;
  final String icon;

  factory BadgeModel.fromJson(Map<dynamic, dynamic> json) => BadgeModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon:
        json['iconUrl'] as String? ??
        json['icon_url'] as String? ??
        json['icon'] as String? ??
        '',
  );
}
