import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'package:projectuas/audio/audio_manager.dart';

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
  StreamSubscription? _completedSub;
  StreamSubscription? _laguChangedSub;

  List<Map<String, dynamic>> get _playlist =>
      AudioManager.instance.currentPlaylist.isNotEmpty
          ? AudioManager.instance.currentPlaylist
          : widget.playlist;

  @override
  void initState() {
    super.initState();
    _judul = widget.judul;
    _artis = widget.artis;
    _audioUrl = widget.audioUrl;
    _coverUrl = widget.coverUrl;
    _currentIndex = widget.currentIndex;

    if (AudioManager.instance.currentPlaylist.isEmpty && widget.playlist.isNotEmpty) {
      AudioManager.instance.currentPlaylist = widget.playlist;
      AudioManager.instance.currentIndex = widget.currentIndex;
    }

    _initPlayer();

    _laguChangedSub = AudioManager.instance.laguChangedStream.listen((_) {
      if (!mounted) return;
      setState(() {
        _judul = AudioManager.instance.currentJudul ?? _judul;
        _artis = AudioManager.instance.currentArtis ?? _artis;
        _audioUrl = AudioManager.instance.currentUrl ?? _audioUrl;
        _coverUrl = AudioManager.instance.currentCoverUrl;
        _currentIndex = AudioManager.instance.currentIndex;
        _position = Duration.zero;
        _duration = Duration.zero;
        isLoading = false;
      });
      _resubscribeStreams();
    });
  }

  void _resubscribeStreams() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();

    _durationSub = _player.durationStream.listen((d) {
      if (mounted) setState(() => _duration = d ?? Duration.zero);
    });
    _positionSub = _player.positionStream.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _playingSub = _player.playingStream.listen((playing) {
      if (mounted) setState(() => isPlaying = playing);
    });
    _completedSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_currentIndex < _playlist.length - 1) {
          _changeLagu(_currentIndex + 1);
        } else {
          _player.seek(Duration.zero);
          _player.pause();
        }
      }
    });
  }

  Future<void> _initPlayer() async {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();

    try {
      final isSame = AudioManager.instance.currentUrl == _audioUrl;
      final isActive = isSame && (_player.playing || _player.position > Duration.zero);

      if (isActive) {
        if (mounted) {
          setState(() {
            isLoading = false;
            isPlaying = _player.playing;
            _duration = _player.duration ?? Duration.zero;
            _position = _player.position;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = true);

        AudioManager.instance.currentUrl = _audioUrl;
        AudioManager.instance.currentJudul = _judul;
        AudioManager.instance.currentArtis = _artis;
        AudioManager.instance.currentCoverUrl = _coverUrl;
        AudioManager.instance.currentIndex = _currentIndex;
        await _player.setUrl(_audioUrl);

        if (mounted) setState(() => isLoading = false);
        _player.play();
      }

      _resubscribeStreams();
    } catch (e) {
      debugPrint('Error initPlayer: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(
          context,
          message: 'Gagal memuat audio',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _changeLagu(int newIndex) async {
    if (_playlist.isEmpty) return;
    if (newIndex < 0 || newIndex >= _playlist.length) return;

    final lagu = _playlist[newIndex];
    final newUrl = lagu['audio_url'] ?? '';

    if (mounted) {
      setState(() {
        _currentIndex = newIndex;
        _judul = lagu['judul'] ?? '';
        _artis = lagu['artis'] ?? '';
        _audioUrl = newUrl;
        _coverUrl = lagu['cover_url'];
        isLoading = true;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }

    try {
      await _player.setUrl(newUrl);

      AudioManager.instance.currentUrl = newUrl;
      AudioManager.instance.currentJudul = _judul;
      AudioManager.instance.currentArtis = _artis;
      AudioManager.instance.currentCoverUrl = _coverUrl;
      AudioManager.instance.currentIndex = newIndex;

      _player.play();
    } catch (e) {
      debugPrint('Error changeLagu: $e');
      if (mounted) {
        showTopNotif(
          context,
          message: 'Gagal memuat lagu',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }

    _resubscribeStreams();
  }

  @override
  void dispose() {
    _durationSub?.cancel();
    _positionSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _laguChangedSub?.cancel();
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
    if (_playlist.isEmpty || _currentIndex <= 0) {
      _player.seek(Duration.zero);
    } else {
      _changeLagu(_currentIndex - 1);
    }
  }

  void _next() {
    if (_playlist.isEmpty || _currentIndex >= _playlist.length - 1) {
      showTopNotif(
        context,
        message: 'Tidak ada lagu berikutnya',
        backgroundColor: Colors.orange,
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
                // AppBar
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

                // Card Player
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
                              // Cover
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
                                          placeholder: (context, url) => Container(
                                            color: Colors.blue[50],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              _coverFallback(),
                                        )
                                      : _coverFallback(),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Judul & Artis
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

                              // Progress Bar
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
                                  value: _position.inSeconds
                                      .toDouble()
                                      .clamp(0, _duration.inSeconds.toDouble()),
                                  min: 0,
                                  max: _duration.inSeconds.toDouble() > 0
                                      ? _duration.inSeconds.toDouble()
                                      : 1,
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.grey[300],
                                  onChanged: _seekTo,
                                ),
                              ),

                              // Waktu
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                              // Kontrol
                              isLoading
                                  ? const CircularProgressIndicator()
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Previous
                                        IconButton(
                                          onPressed: _previous,
                                          icon: Icon(
                                            Icons.skip_previous_rounded,
                                            size: 40,
                                            color: _playlist.isEmpty || _currentIndex == 0
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
                                                color: Colors.blue.withOpacity(0.4),
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
                                            color: _playlist.isEmpty ||
                                                    _currentIndex == _playlist.length - 1
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

                // Footer
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