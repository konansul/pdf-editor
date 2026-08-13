class Folder {
  final String id;
  final String name;
  final DateTime createdAt;

  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Folder.fromRow(Map<String, Object?> row) {
    return Folder(
      id: row['id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }
}
