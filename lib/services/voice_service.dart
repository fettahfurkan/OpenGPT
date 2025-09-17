import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/voice_settings.dart';

class VoiceService extends ChangeNotifier {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  VoiceSettings _voiceSettings = const VoiceSettings();
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  
  // Getters
  VoiceSettings get voiceSettings => _voiceSettings;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;

  // TTS için mevcut sesler
  List<dynamic> _availableVoices = [];
  List<dynamic> get availableVoices => _availableVoices;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // TTS başlatma
      await _initializeTts();
      
      // Speech to Text başlatma
      await _initializeSpeechToText();
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('VoiceService initialization error: $e');
    }
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage(_voiceSettings.language);
    await _flutterTts.setSpeechRate(_voiceSettings.speechRate);
    await _flutterTts.setPitch(_voiceSettings.pitch);
    
    // Mevcut sesleri al
    _availableVoices = await _flutterTts.getVoices;
    
    // Cinsiyet ayarına göre ses seç
    await _setVoiceByGender(_voiceSettings.voiceGender);
    
    // TTS durumlarını dinle
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      notifyListeners();
    });
    
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint('TTS Error: $msg');
    });
  }

  Future<void> _initializeSpeechToText() async {
    // Mikrofon izni kontrol et
    final microphoneStatus = await Permission.microphone.status;
    if (!microphoneStatus.isGranted) {
      await Permission.microphone.request();
    }
    
    // Speech to Text başlat
    bool available = await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech to Text Error: $error');
        _isListening = false;
        notifyListeners();
      },
      onStatus: (status) {
        debugPrint('Speech to Text Status: $status');
        if (status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
    );
    
    if (!available) {
      debugPrint('Speech to Text not available');
    }
  }

  Future<void> _setVoiceByGender(String gender) async {
    if (_availableVoices.isEmpty) return;
    
    // Tüm mevcut sesleri debug için yazdır
    debugPrint('=== Mevcut Sesler ===');
    for (var voice in _availableVoices) {
      debugPrint('Ses: ${voice['name']}, Locale: ${voice['locale']}');
    }
    debugPrint('===================');
    
    // Önce Türkçe sesler arasından seçim yap
    var turkishVoices = _availableVoices.where((voice) {
      final locale = voice['locale']?.toString().toLowerCase() ?? '';
      return locale.contains('tr') || locale.contains('turkish');
    }).toList();
    
    // Eğer Türkçe ses yoksa, tüm sesleri kullan
    if (turkishVoices.isEmpty) {
      turkishVoices = _availableVoices;
      debugPrint('Türkçe ses bulunamadı, tüm sesler kullanılacak');
    }
    
    if (turkishVoices.isNotEmpty) {
      dynamic selectedVoice;
      
      if (gender == 'female') {
        // Kadın sesi için arama kriterleri
        selectedVoice = turkishVoices.firstWhere(
          (voice) {
            final name = voice['name']?.toString().toLowerCase() ?? '';
            final locale = voice['locale']?.toString().toLowerCase() ?? '';
            
            // Kadın sesini belirten kelimeler
            return name.contains('female') || 
                   name.contains('woman') || 
                   name.contains('kadın') ||
                   name.contains('yelda') ||
                   name.contains('zeynep') ||
                   name.contains('elif') ||
                   name.contains('ayşe') ||
                   name.contains('fatma') ||
                   name.contains('seda') ||
                   name.contains('defne') ||
                   name.contains('tr-tr-yelda') ||
                   name.contains('tr-tr-defne') ||
                   (locale.contains('tr') && name.contains('f')) ||
                   name.contains('#female') ||
                   name.contains('_female') ||
                   name.contains('-female');
          },
          orElse: () => null,
        );
        
        // Eğer kadın sesi bulunamazsa, pitch ve speech rate ile kadın sesi simüle et
         if (selectedVoice == null) {
           selectedVoice = turkishVoices.first;
           // Kadın sesi için: yüksek pitch, biraz hızlı konuşma
           await _flutterTts.setPitch(1.3);
           await _flutterTts.setSpeechRate(_voiceSettings.speechRate * 1.1);
           debugPrint('Kadın sesi bulunamadı, pitch yükseltildi ve hız artırıldı');
         } else {
           await _flutterTts.setPitch(_voiceSettings.pitch);
           await _flutterTts.setSpeechRate(_voiceSettings.speechRate);
           debugPrint('Kadın sesi seçildi: ${selectedVoice['name']}');
         }
      } else {
        // Erkek sesi için arama kriterleri
        selectedVoice = turkishVoices.firstWhere(
          (voice) {
            final name = voice['name']?.toString().toLowerCase() ?? '';
            final locale = voice['locale']?.toString().toLowerCase() ?? '';
            
            // Erkek sesini belirten kelimeler
            return name.contains('male') || 
                   name.contains('man') || 
                   name.contains('erkek') ||
                   name.contains('murat') ||
                   name.contains('ahmet') ||
                   name.contains('mehmet') ||
                   name.contains('ali') ||
                   name.contains('emre') ||
                   name.contains('tolga') ||
                   name.contains('tr-tr-tolga') ||
                   name.contains('tr-tr-murat') ||
                   (locale.contains('tr') && name.contains('m')) ||
                   name.contains('#male') ||
                   name.contains('_male') ||
                   name.contains('-male');
          },
          orElse: () => null,
        );
        
        // Eğer erkek sesi bulunamazsa, pitch ve speech rate ile erkek sesi simüle et
         if (selectedVoice == null) {
           selectedVoice = turkishVoices.first;
           // Erkek sesi için: düşük pitch, biraz yavaş konuşma
           await _flutterTts.setPitch(0.7);
           await _flutterTts.setSpeechRate(_voiceSettings.speechRate * 0.9);
           debugPrint('Erkek sesi bulunamadı, pitch düşürüldü ve hız azaltıldı');
         } else {
           await _flutterTts.setPitch(_voiceSettings.pitch);
           await _flutterTts.setSpeechRate(_voiceSettings.speechRate);
           debugPrint('Erkek sesi seçildi: ${selectedVoice['name']}');
         }
      }
      
      // Seçilen sesi ayarla
      await _flutterTts.setVoice({
        'name': selectedVoice['name'],
        'locale': selectedVoice['locale'],
      });
      
      debugPrint('Seçilen ses: ${selectedVoice['name']}, Cinsiyet: $gender');
    }
  }

  Future<void> updateVoiceSettings(VoiceSettings newSettings) async {
    _voiceSettings = newSettings;
    
    if (_isInitialized) {
      await _flutterTts.setLanguage(newSettings.language);
      await _flutterTts.setSpeechRate(newSettings.speechRate);
      
      // Ses cinsiyetini ayarla (pitch ayarı _setVoiceByGender içinde yapılacak)
      await _setVoiceByGender(newSettings.voiceGender);
    }
    
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!_voiceSettings.isTtsEnabled || text.trim().isEmpty) return;
    
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Speak error: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Stop speaking error: $e');
    }
  }

  Future<void> startListening({
    Function(String)? onResult,
    Function(String)? onPartialResult,
  }) async {
    if (!_voiceSettings.isSpeechToTextEnabled || _isListening) return;
    
    try {
      // Önce konuşmayı durdur
      await stopSpeaking();
      
      _recognizedText = '';
      _isListening = true;
      notifyListeners();
      
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          if (result.finalResult) {
            _isListening = false;
            onResult?.call(_recognizedText);
          } else {
            onPartialResult?.call(_recognizedText);
          }
          notifyListeners();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: _voiceSettings.language,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Start listening error: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Stop listening error: $e');
    }
  }

  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return true;
  }

  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}