class SystemPrompt {
  final String id;
  final String name;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDefault;
  final bool isActive;

  SystemPrompt({
    required this.id,
    required this.name,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.isActive = false,
  });

  /// Veritabanından Map'den SystemPrompt oluşturmak için factory constructor
  factory SystemPrompt.fromMap(Map<String, dynamic> map) {
    return SystemPrompt(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isDefault: (map['isDefault'] as int) == 1,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  /// SystemPrompt'u veritabanına kaydetmek için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault ? 1 : 0,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Yeni sistem promptu oluşturmak için factory constructor
  factory SystemPrompt.create({
    required String name,
    required String content,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return SystemPrompt(
      id: 'sp_${now.millisecondsSinceEpoch}',
      name: name,
      content: content,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
      isActive: false,
    );
  }

  /// Varsayılan sistem promptu oluşturmak için factory constructor
  factory SystemPrompt.defaultPrompt() {
    final now = DateTime.now();
    return SystemPrompt(
      id: 'sp_default',
      name: 'Varsayılan',
      content:
          'Sen yardımsever, bilgili ve dostane bir AI asistanısın. Kullanıcılara en iyi şekilde yardım etmeye odaklan. Türkçe dilinde doğal ve anlaşılır cevaplar ver.',
      createdAt: now,
      updatedAt: now,
      isDefault: true,
      isActive: true,
    );
  }

  /// İçeriği güncellenmesi için copy methodu
  SystemPrompt copyWithContent(String newContent) {
    return SystemPrompt(
      id: id,
      name: name,
      content: newContent,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault,
      isActive: isActive,
    );
  }

  /// Adı güncellenmesi için copy methodu
  SystemPrompt copyWithName(String newName) {
    return SystemPrompt(
      id: id,
      name: newName,
      content: content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault,
      isActive: isActive,
    );
  }

  /// Aktif durumu güncellenmesi için copy methodu
  SystemPrompt copyWithActiveStatus(bool newIsActive) {
    return SystemPrompt(
      id: id,
      name: name,
      content: content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isDefault: isDefault,
      isActive: newIsActive,
    );
  }

  @override
  String toString() {
    return 'SystemPrompt(id: $id, name: $name, isDefault: $isDefault, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SystemPrompt &&
        other.id == id &&
        other.name == name &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isDefault == isDefault &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        content.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isDefault.hashCode ^
        isActive.hashCode;
  }
}
