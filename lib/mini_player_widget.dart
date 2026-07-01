import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/audio/audio_manager.dart';
import 'package:projectuas/pages/player_page.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AudioManager.instance.laguChangedStream,
      builder: (context, _) {
        return StreamBuilder(
          stream: AudioManager.instance.player.playerStateStream,
          builder: (context, snapshot) {
            final url = AudioManager.instance.currentUrl;

            if (url == null || url.isEmpty) {
              return const SizedBox.shrink();
            }

            final judul = AudioManager.instance.currentJudul ?? 'Sedang Diputar';
            final artis = AudioManager.instance.currentArtis ?? '';
            final coverUrl = AudioManager.instance.currentCoverUrl;
            final playing = AudioManager.instance.player.playing;
            final currentIndex = AudioManager.instance.currentIndex;
            final playlistLength = AudioManager.instance.currentPlaylist.length;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerPage(
                      judul: judul,
                      artis: artis,
                      audioUrl: url,
                      coverUrl: coverUrl,
                      playlist: AudioManager.instance.currentPlaylist,
                      currentIndex: currentIndex,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00897B), Color(0xFF00695C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── Row utama ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Row(
                        children: [

                          // ── Cover Art ──
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: coverUrl != null && coverUrl.toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: coverUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _coverFallback(),
                                  )
                                : _coverFallback(),
                          ),

                          const SizedBox(width: 10),

                          // ── Judul & Artis ──
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  judul,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                if (artis.isNotEmpty)
                                  Text(
                                    artis,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.75),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // ── Tombol Previous ──
                          IconButton(
                            onPressed: currentIndex <= 0 && playlistLength > 0
                                ? null // ← disabled jika lagu pertama
                                : () async {
                                    await AudioManager.instance.previous();
                                  },
                            icon: Icon(
                              Icons.skip_previous_rounded,
                              size: 26,
                              color: currentIndex <= 0 && playlistLength > 0
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          const SizedBox(width: 4),

                          // ── Tombol Play/Pause ──
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {
                                playing
                                    ? AudioManager.instance.player.pause()
                                    : AudioManager.instance.player.play();
                              },
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // ── Tombol Next ──
                          IconButton(
                            onPressed: currentIndex >= playlistLength - 1
                                ? null // ← disabled jika lagu terakhir
                                : () async {
                                    await AudioManager.instance.next();
                                  },
                            icon: Icon(
                              Icons.skip_next_rounded,
                              size: 26,
                              color: currentIndex >= playlistLength - 1
                                  ? Colors.white.withOpacity(0.4)
                                  : Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    // ── Progress Bar ──
                    StreamBuilder<Duration>(
                      stream: AudioManager.instance.player.positionStream,
                      builder: (context, posSnapshot) {
                        final position = posSnapshot.data ?? Duration.zero;
                        final duration =
                            AudioManager.instance.player.duration ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds / duration.inMilliseconds
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _coverFallback() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.teal[300],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}