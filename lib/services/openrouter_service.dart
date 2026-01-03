import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'database_helper.dart';

class OpenRouterService {
  // OpenRouter API ayarları
  static const String _baseUrl =
      "https://openrouter.ai/api/v1/chat/completions";
  static final DatabaseHelper _dbHelper = DatabaseHelper();

  // Cache için
  static String? _cachedApiKey;
  static String? _cachedModel;
  static Map<String, String>? _cachedModels;
  static const String _siteUrl = "YOUR_SITE_URL_HERE"; // Opsiyonel
  static const String _siteTitle = "YOUR_SITE_NAME_HERE"; // Opsiyonel

  // Varsayılan sistem promptu - AI'ın davranışını belirler
  static const String _defaultSystemPrompt = "TÜRKÇE DİLİNE ÖZEL BOT";

  // Dinamik sistem promptu - uygulama içinden değiştirilebilir
  static String _currentSystemPrompt = _defaultSystemPrompt;

  /// Aktif API key'i döndürür
  static Future<String> get apiKey async {
    if (_cachedApiKey != null) return _cachedApiKey!;

    final activeKey = await _dbHelper.getActiveApiKey();
    _cachedApiKey = activeKey?['keyValue'] ?? '';
    return _cachedApiKey!;
  }

  /// Aktif modeli döndürür
  static Future<String> get currentModel async {
    if (_cachedModel != null) return _cachedModel!;

    final activeModel = await _dbHelper.getActiveModel();
    _cachedModel = activeModel?['apiModel'] ?? 'x-ai/grok-4.1-fast:free';
    return _cachedModel!;
  }

  /// Cache'i temizler
  static void clearCache() {
    _cachedApiKey = null;
    _cachedModel = null;
    _cachedModels = null;
  }

  /// Kullanılabilir modelleri döndürür
  static Future<Map<String, String>> get availableModels async {
    if (_cachedModels != null) return _cachedModels!;

    final models = await _dbHelper.getModels();
    _cachedModels = {};
    for (var model in models) {
      _cachedModels![model['name']] = model['apiModel'];
    }
    return _cachedModels!;
  }

  /// Model adını döndürür
  static Future<String> get modelName async {
    final activeModel = await _dbHelper.getActiveModel();
    return activeModel?['name'] ?? 'Bilinmeyen';
  }

  /// Modeli değiştirir
  static Future<void> changeModel(String modelName) async {
    final models = await _dbHelper.getModels();
    final targetModel = models.firstWhere(
      (model) => model['name'] == modelName,
      orElse: () => {},
    );

    if (targetModel.isNotEmpty) {
      await _dbHelper.setActiveModel(targetModel['id']);
      _cachedModel = targetModel['apiModel'];
    }
  }

  /// OpenRouter API'sine mesaj gönderir ve yanıt alır
  /// [conversationHistory] parametresi ile konuşma geçmişini korur (sistem promptu dahil)
  /// [imageBytes] parametresi ile fotoğraf gönderebilir
  static Future<String> sendMessage(
    String userMessage, {
    List<Map<String, dynamic>>? conversationHistory,
    Uint8List? imageBytes,
  }) async {
    final apiKeyValue = await apiKey;
    final modelValue = await currentModel;

    final headers = {
      'Authorization': 'Bearer $apiKeyValue',
      'Content-Type': 'application/json; charset=utf-8',
      'HTTP-Referer': _siteUrl,
      'X-Title': _siteTitle,
    };

    // Konuşma geçmişini oluştur
    List<Map<String, dynamic>> messages = [];

    // Konuşma geçmişi varsa ekle (sistem promptu ChatPage'te zaten eklendi)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      messages.addAll(conversationHistory);
    } else {
      // Fallback: Eğer hiç geçmiş yoksa varsayılan sistem promptunu ekle
      messages.add({'role': 'system', 'content': _currentSystemPrompt});
    }

    // Yeni kullanıcı mesajını ekle (fotoğraf ile birlikte)
    if (imageBytes != null) {
      // Fotoğraf varsa multimodal format kullan
      final base64Image = base64Encode(imageBytes);
      final mimeType =
          lookupMimeType('', headerBytes: imageBytes.take(12).toList()) ??
          'image/jpeg';

      messages.add({
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userMessage},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
          },
        ],
      });
    } else {
      // Sadece metin mesajı
      messages.add({'role': 'user', 'content': userMessage});
    }

    final body = {'model': modelValue, 'messages': messages};

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception(
          'API çağrısı başarısız: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      throw Exception('Bağlantı hatası: $e');
    }
  }

  /// API key'in geçerli olup olmadığını kontrol eder
  static Future<bool> get hasValidApiKey async {
    final apiKeyValue = await apiKey;
    return apiKeyValue.isNotEmpty;
  }

  /// Mevcut sistem promptunu döndürür
  static String get currentSystemPrompt => _currentSystemPrompt;

  /// Varsayılan sistem promptunu döndürür
  static String get defaultSystemPrompt => _defaultSystemPrompt;

  /// Sistem promptunu günceller
  static void updateSystemPrompt(String newPrompt) {
    _currentSystemPrompt = newPrompt.trim().isEmpty
        ? _defaultSystemPrompt
        : newPrompt;
  }

  /// Sistem promptunu varsayılana sıfırlar
  static void resetSystemPrompt() {
    _currentSystemPrompt = _defaultSystemPrompt;
  }
}
