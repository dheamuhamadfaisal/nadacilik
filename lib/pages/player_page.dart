import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/pages/snackbar_helper.dart';
import 'audio_manager.dart';

class PlayerPage extends StatefulWidget {
  final String judul;
  final String artis;
  final String audioUrl;
  final String? coverUrl;
  final List<Map<String, dynamic>> playlist;
  final int currentIndex;

  const PlayerPage({
    super.key,
    required this.judul,
    required this.artis,
    required this.audioUrl,
    this.coverUrl,
    this.playlist = const [],
    this.currentIndex = 0,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  AudioPlayer get _player => AudioManager.instance.player;

  bool isLoading = true;
  bool isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  late String _judul;
  late String _artis;
  late String _audioUrl;
  late String? _coverUrl;
  late int _currentIndex;

  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _playingSub;

  @override
  void initState() {
    super.initState();
    _judul = widget.judul;
    _artis = widget.artis;
    _audioUrl = widget.audioUrl;
    _coverUrl = widget.coverUrl;
    _currentIndex = widget.currentIndex;
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    // Cancel semua subscription lama terlebih dahulu
    await _durationSub?.cancel();
    await _positionSub?.cancel();
    await _playingSub?.cancel();

    try {
      // ── FIX BUG 1: Cek apakah lagu yang sama sedang berjalan ──
      // Jika URL sama & audio sudah aktif → jangan reset, sync UI saja
      final isSameUrl = AudioManager.instance.currentUrl == _audioUrl;
      final isAlreadyActive =
          isSameUrl && (_player.playing || _player.position > Duration.zero);

      if (isAlreadyActive) {
        // Lanjutkan lagu yang sedang berjalan, hanya sync state UI
        if (mounted) {
          setState(() {
            isLoading = false;
            isPlaying = _player.playing;
            _duration = _player.duration ?? Duration.zero;
            _position = _player.position;
          });
        }
      } else {
        // Lagu baru atau belum pernah diputar → load ulang
        if (mounted) setState(() => isLoading = true);

        // Catat URL aktif ke AudioManager SEBELUM setUrl
        AudioManager.instance.currentUrl = _audioUrl;

        await _player.stop();
        await _player.setUrl(_audioUrl);

        if (mounted) setState(() => isLoading = false);

        _player.play();
      }

      // Pasang stream listener (selalu dipasang ulang setiap masuk halaman)
      _durationSub = _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _positionSub = _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _playingSub = _player.playingStream.listen((playing) {
        if (mounted) setState(() => isPlaying = playing);
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(
          context,
          message: 'Gagal memuat audio: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  // ── FIX BUG 2: Ganti lagu tanpa race condition ──
  Future<void> _changeLagu(int newIndex) async {
    if (widget.playlist.isEmpty) return;
    if (newIndex < 0 || newIndex >= widget.playlist.length) return;

    final lagu = widget.playlist[newIndex];

    // Simpan semua nilai ke variabel lokal SEBELUM setState
    final newUrl = lagu['audio_url'] ?? '';
    final newJudul = lagu['judul'] ?? '';
    final newArtis = lagu['artis'] ?? '';
    final newCover = lagu['cover_url'];

    // Cancel subscription lama sebelum ganti lagu
    await _durationSub?.cancel();
    await _positionSub?.cancel();
    await _playingSub?.cancel();

    if (mounted) {
      setState(() {
        _currentIndex = newIndex;
        _judul = newJudul;
        _artis = newArtis;
        _audioUrl = newUrl;
        _coverUrl = newCover;
        isLoading = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    try {
      // Update AudioManager dengan URL baru
      AudioManager.instance.currentUrl = newUrl;

      await _player.stop();

      // Gunakan newUrl (variabel lokal)
      await _player.setUrl(newUrl);

      if (mounted) setState(() => isLoading = false);

      // Pasang ulang stream listener
      _durationSub = _player.durationStream.listen((d) {
        if (mounted) setState(() => _duration = d ?? Duration.zero);
      });

      _positionSub = _player.positionStream.listen((p) {
        if (mounted) setState(() => _position = p);
      });

      _playingSub = _player.playingStream.listen((playing) {
        if (mounted) setState(() => isPlaying = playing);
      });

      _player.play();
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(
          context,
          message: 'Gagal memuat audio: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    super.dispose();
  }

  String _formatDurasi(Duration d) {
    final menit = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final detik = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$menit:$detik';
  }

  void _seekTo(double value) {
    _player.seek(Duration(seconds: value.toInt()));
  }

  void _togglePlay() {
    isPlaying ? _player.pause() : _player.play();
  }

  void _previous() {
    if (widget.playlist.isEmpty) {
      _player.seek(Duration.zero);
    } else {
      _changeLagu(_currentIndex - 1);
    }
  }

  void _next() {
    if (widget.playlist.isEmpty) {
      showTopNotif(
        context,
        message: 'Tidak Ada Lagu Berikutnya',
        backgroundColor: Colors.red,
      );
    } else {
      _changeLagu(_currentIndex + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── AppBar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Sedang Diputar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black38,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Card Player ──
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ── Cover ──
                              Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _coverUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: _coverUrl!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                                color: Colors.blue[50],
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              _coverFallback(),
                                        )
                                      : _coverFallback(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── Judul & Artis ──
                              Text(
                                _judul,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _artis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // ── Progress Bar ──
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12,
                                  ),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  value: _position.inSeconds.toDouble().clamp(
                                    0,
                                    _duration.inSeconds.toDouble(),
                                  ),
                                  min: 0,
                                  max: _duration.inSeconds.toDouble() > 0
                                      ? _duration.inSeconds.toDouble()
                                      : 1,
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.grey[300],
                                  onChanged: _seekTo,
                                ),
                              ),

                              // ── Waktu ──
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDurasi(_position),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                    Text(
                                      _formatDurasi(_duration),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Kontrol ──
                              isLoading
                                  ? const CircularProgressIndicator()
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Previous
                                        IconButton(
                                          onPressed: _previous,
                                          icon: Icon(
                                            Icons.skip_previous_rounded,
                                            size: 40,
                                            color:
                                                widget.playlist.isEmpty ||
                                                    _currentIndex == 0
                                                ? Colors.grey[400]
                                                : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Play/Pause
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(
                                                  0.4,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            onPressed: _togglePlay,
                                            icon: Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Next
                                        IconButton(
                                          onPressed: _next,
                                          icon: Icon(
                                            Icons.skip_next_rounded,
                                            size: 40,
                                            color:
                                                widget.playlist.isEmpty ||
                                                    _currentIndex ==
                                                        widget.playlist.length -
                                                            1
                                                ? Colors.grey[400]
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Footer ──
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '© 2026 Nada Cilik',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverFallback() {
    return Container(
      color: Colors.blue[50],
      child: const Icon(Icons.music_note_rounded, size: 60, color: Colors.blue),
    );
  }
}
