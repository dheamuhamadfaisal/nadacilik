import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer player = AudioPlayer();
  
  String? currentUrl;
  String? currentJudul;
  String? currentArtis;
  String? currentCoverUrl;
  
  Future<void> playLagu({
    required String judul,
    required String artis,
    required String audioUrl,
    String? coverUrl,
  })async{
    if (currentUrl == audioUrl && player.playing){
      return;
    }
    currentUrl = audioUrl;
    currentJudul = judul;
    currentArtis = artis;
    currentCoverUrl = coverUrl;

    await player.setUrl(audioUrl);
    player.play();
  }

  bool isSameSong(String audioUrl){
    return currentUrl == audioUrl;
  }
}