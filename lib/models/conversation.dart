class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? systemPromptId;
  final int messageCount;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.systemPromptId,
    this.messageCount = 0,
  });

  /// Veritabanından Map'den Conversation oluşturmak için factory constructor
  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      systemPromptId: map['systemPromptId'] as String?,
      messageCount: map['messageCount'] as int? ?? 0,
    );
  }

  /// Conversation'ı veritabanına kaydetmek için Map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'systemPromptId': systemPromptId,
      'messageCount': messageCount,
    };
  }

  /// Yeni konuşma oluşturmak için factory constructor
  factory Conversation.create({required String title, String? systemPromptId}) {
    final now = DateTime.now();
    return Conversation(
      id: 'conv_${now.millisecondsSinceEpoch}',
      title: title,
      createdAt: now,
      updatedAt: now,
      systemPromptId: systemPromptId,
      messageCount: 0,
    );
  }

  /// Başlığı güncellenmesi için copy methodu
  Conversation copyWithTitle(String newTitle) {
    return Conversation(
      id: id,
      title: newTitle,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      systemPromptId: systemPromptId,
      messageCount: messageCount,
    );
  }

  /// Mesaj sayısını güncellenmesi için copy methodu
  Conversation copyWithMessageCount(int newMessageCount) {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      systemPromptId: systemPromptId,
      messageCount: newMessageCount,
    );
  }

  /// System prompt'u güncellenmesi için copy methodu
  Conversation copyWithSystemPrompt(String? newSystemPromptId) {
    return Conversation(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      systemPromptId: newSystemPromptId,
      messageCount: messageCount,
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, title: $title, messageCount: $messageCount, systemPromptId: $systemPromptId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Conversation &&
        other.id == id &&
        other.title == title &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.systemPromptId == systemPromptId &&
        other.messageCount == messageCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        systemPromptId.hashCode ^
        messageCount.hashCode;
  }
}
