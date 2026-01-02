/// Example entity - Domain layer
class ExampleEntity {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;

  const ExampleEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  ExampleEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
  }) {
    return ExampleEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExampleEntity &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, title, description, createdAt);
}
