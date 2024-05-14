class Trigger {
  final String id;
  final String name;
  final String description;

  const Trigger(
      {required this.id, required this.name, required this.description});

  factory Trigger.fromJson(Map<String, dynamic> json) => Trigger(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '');

  Map<String, dynamic> toJson() =>
      {"id": id, "name": name, "description": description};
}
