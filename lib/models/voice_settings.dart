class VoiceSettings {
  final bool isTtsEnabled;
  final bool isSpeechToTextEnabled;
  final String voiceGender; // 'male' veya 'female'
  final double speechRate;
  final double pitch;
  final String language;

  const VoiceSettings({
    this.isTtsEnabled = false,
    this.isSpeechToTextEnabled = true,
    this.voiceGender = 'female',
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.language = 'tr-TR',
  });

  VoiceSettings copyWith({
    bool? isTtsEnabled,
    bool? isSpeechToTextEnabled,
    String? voiceGender,
    double? speechRate,
    double? pitch,
    String? language,
  }) {
    return VoiceSettings(
      isTtsEnabled: isTtsEnabled ?? this.isTtsEnabled,
      isSpeechToTextEnabled:
          isSpeechToTextEnabled ?? this.isSpeechToTextEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isTtsEnabled': isTtsEnabled,
      'isSpeechToTextEnabled': isSpeechToTextEnabled,
      'voiceGender': voiceGender,
      'speechRate': speechRate,
      'pitch': pitch,
      'language': language,
    };
  }

  factory VoiceSettings.fromJson(Map<String, dynamic> json) {
    return VoiceSettings(
      isTtsEnabled: json['isTtsEnabled'] ?? false,
      isSpeechToTextEnabled: json['isSpeechToTextEnabled'] ?? true,
      voiceGender: json['voiceGender'] ?? 'female',
      speechRate: json['speechRate']?.toDouble() ?? 0.5,
      pitch: json['pitch']?.toDouble() ?? 1.0,
      language: json['language'] ?? 'tr-TR',
    );
  }

  @override
  String toString() {
    return 'VoiceSettings(isTtsEnabled: $isTtsEnabled, isSpeechToTextEnabled: $isSpeechToTextEnabled, voiceGender: $voiceGender, speechRate: $speechRate, pitch: $pitch, language: $language)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceSettings &&
        other.isTtsEnabled == isTtsEnabled &&
        other.isSpeechToTextEnabled == isSpeechToTextEnabled &&
        other.voiceGender == voiceGender &&
        other.speechRate == speechRate &&
        other.pitch == pitch &&
        other.language == language;
  }

  @override
  int get hashCode {
    return isTtsEnabled.hashCode ^
        isSpeechToTextEnabled.hashCode ^
        voiceGender.hashCode ^
        speechRate.hashCode ^
        pitch.hashCode ^
        language.hashCode;
  }
}
