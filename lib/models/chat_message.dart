import 'dart:typed_data';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? id;
  final String? imagePath;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.id,
    this.imagePath,
    this.imageBytes,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Kullanıcı mesajı oluşturmak için factory constructor
  factory ChatMessage.user(String content, {String? imagePath, Uint8List? imageBytes}) {
    return ChatMessage(
      content: content,
      isUser: true,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      imageBytes: imageBytes,
    );
  }

  /// Bot mesajı oluşturmak için factory constructor
  factory ChatMessage.bot(String content) {
    return ChatMessage(
      content: content,
      isUser: false,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// Hata mesajı oluşturmak için factory constructor
  factory ChatMessage.error(String error) {
    return ChatMessage(
      content: 'Hata: $error',
      isUser: false,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  @override
  String toString() {
    return 'ChatMessage(content: $content, isUser: $isUser, timestamp: $timestamp)';
  }
}