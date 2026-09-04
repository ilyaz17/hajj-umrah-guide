import 'package:flutter_tts/flutter_tts.dart';

class RitualAudioService {
  RitualAudioService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  Future<void> configure() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();

  Future<void> dispose() async {
    await _tts.stop();
  }
}
