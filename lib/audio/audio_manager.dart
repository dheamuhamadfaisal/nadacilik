import 'dart:async';
import 'package:just_audio/just_audio.dart';

class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  final AudioPlayer player = AudioPlayer();
  String? currentUrl;
  String? currentJudul;
  String? currentArtis;
  String? currentCoverUrl;
  List<Map<String, dynamic>> currentPlaylist = [];
  int currentIndex = 0;

  final _laguChangedController = StreamController<void>.broadcast();
  Stream<void> get laguChangedStream => _laguChangedController.stream;

  Future<void> playLagu({
    required String judul,
    required String artis,
    required String audioUrl,
    String? coverUrl,
    List<Map<String, dynamic>>? playlist,
    int index = 0,
  }) async {
    if (currentUrl == audioUrl && player.playing) return;

    currentUrl = audioUrl;
    currentJudul = judul;
    currentArtis = artis;
    currentCoverUrl = coverUrl;

    if (playlist != null) {
      currentPlaylist = playlist;
      currentIndex = index;
    }

    await player.setUrl(audioUrl);
    player.play();
    _laguChangedController.add(null);
  }

  Future<void> next() async {
    if (currentPlaylist.isEmpty) return;
    if (currentIndex >= currentPlaylist.length - 1) return;

    currentIndex++;
    final lagu = currentPlaylist[currentIndex];
    await playLagu(
      audioUrl: lagu['audio_url'] ?? '',
      judul: lagu['judul'] ?? '',
      artis: lagu['artis'] ?? '',
      coverUrl: lagu['cover_url'],
    );
  }

  Future<void> previous() async {
    if (currentPlaylist.isEmpty || currentIndex <= 0) {
      await player.seek(Duration.zero);
      return;
    }

    currentIndex--;
    final lagu = currentPlaylist[currentIndex];
    await playLagu(
      audioUrl: lagu['audio_url'] ?? '',
      judul: lagu['judul'] ?? '',
      artis: lagu['artis'] ?? '',
      coverUrl: lagu['cover_url'],
    );
  }

  bool isSameSong(String audioUrl) => currentUrl == audioUrl;

  void dispose() {
    _laguChangedController.close();
    player.dispose();
  }
}