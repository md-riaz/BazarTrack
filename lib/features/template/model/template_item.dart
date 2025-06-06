class TemplateItem {
  final String id;
  final String name;

  TemplateItem({required this.id, required this.name});

  factory TemplateItem.fromJson(Map<String, dynamic> json) => TemplateItem(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
