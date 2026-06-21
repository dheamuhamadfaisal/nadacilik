import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer player = AudioPlayer();
  
  String? currentUrl;
}