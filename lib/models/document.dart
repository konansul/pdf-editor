class Document {
  final String id;
  final String name;
  final String filePath;
  final String? thumbnailPath;
  final int pageCount;
  final int byteSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;

  const Document({
    required this.id,
    required this.name,
    required this.filePath,
    required this.thumbnailPath,
    required this.pageCount,
    required this.byteSize,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
  });

  Document copyWith({
    String? name,
    String? thumbnailPath,
    int? pageCount,
    int? byteSize,
    DateTime? updatedAt,
  }) {
    return Document(
      id: id,
      name: name ?? this.name,
      filePath: filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      folderId: folderId,
    );
  }

  Map<String, Object?> toRow() {
    return {
      'id': id,
      'name': name,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'page_count': pageCount,
      'byte_size': byteSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'folder_id': folderId,
    };
  }

  factory Document.fromRow(Map<String, Object?> row) {
    return Document(
      id: row['id'] as String,
      name: row['name'] as String,
      filePath: row['file_path'] as String,
      thumbnailPath: row['thumbnail_path'] as String?,
      pageCount: row['page_count'] as int,
      byteSize: row['byte_size'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      folderId: row['folder_id'] as String?,
    );
  }
}

enum DocumentSort { newest, oldest, name }
