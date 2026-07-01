import 'package:flutter/material.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectuas/audio/audio_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/connection/connectivity_helper.dart';
import 'package:projectuas/mini_player_widget.dart';
import 'login_page.dart';
import 'favorit_page.dart';
import 'sleep_page.dart';
import 'edukasi_page.dart';
import 'musik_page.dart';
import 'player_page.dart';
import 'editprofil_page.dart';

final List<Map<String, dynamic>> features = [
  {'icon': Icons.star_rounded, 'label': 'Favorit', 'color': const Color(0xFF4CAF50)},
  {'icon': Icons.nightlight_round, 'label': 'Tidur', 'color': const Color(0xFF5C6BC0)},
  {'icon': Icons.menu_book_rounded, 'label': 'Edukasi', 'color': const Color(0xFFFF9800)},
  {'icon': Icons.music_note_rounded, 'label': 'Musik', 'color': const Color(0xFF29B6F6)},
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = '';
  Map<String, dynamic>? featuredLagu;
  Map<String, dynamic>? _currentPlayingLagu;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchFeaturedLagu();
  }

  // Update mini player setiap kembali ke halaman ini
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMiniPlayer();
  }

  void _updateMiniPlayer() {
    final url = AudioManager.instance.currentUrl;
    if (url == null || url.isEmpty) return;

    if (featuredLagu != null && featuredLagu!['audio_url'] == url) {
      if (mounted) setState(() => _currentPlayingLagu = featuredLagu);
    }
  }

  Future<void> _fetchFeaturedLagu() async {
    final adaKoneksi = await cekKoneksi(); 
    if (!adaKoneksi) {
      if (mounted) {
        showTopNotif(
          context,
          message: 'Tidak Ada Koneksi Internet!',
          backgroundColor: Colors.red,
        );
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lagu')
          .get();

      final featured = snapshot.docs
          .where((doc) => doc['featured'] == true)
          .toList();

      if (featured.isNotEmpty) {
        setState(() {
          featuredLagu = featured.first.data();
        });
        debugPrint('Featured lagu berhasil dimuat.');
      } else {
        debugPrint('Tidak ada lagu featured ditemukan.');
      }
    } catch (e) {
      debugPrint('Error fetching featured lagu: $e');
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Pengguna';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _onFeatureTap(String label) {
    if (label == 'Favorit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritPage()));
    } else if (label == 'Tidur') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepPage()));
    } else if (label == 'Edukasi') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const EdukasiPage()));
    } else if (label == 'Musik') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MusikPage()));
    }
  }

  void _onCeritaTap() {
    if (featuredLagu == null) return;
    setState(() => _currentPlayingLagu = featuredLagu);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          judul: featuredLagu!['judul'] ?? 'Lagu Pilihan',
          artis: featuredLagu!['artis'] ?? '',
          audioUrl: featuredLagu!['audio_url'] ?? '',
          coverUrl: featuredLagu!['cover_url'],
        ),
      ),
    ).then((_) => setState(() {})); 
  }

  // Widget mini player
  Widget MiniPlayerWid() {
    final isPlaying = AudioManager.instance.player.playing;
    final hasPosition = AudioManager.instance.player.position > Duration.zero;
    final url = AudioManager.instance.currentUrl ?? '';

    if ((!isPlaying && !hasPosition) || url.isEmpty) {
      return const SizedBox.shrink();
    }

    final judul = _currentPlayingLagu?['judul'] ?? 'Sedang Diputar';
    final artis = _currentPlayingLagu?['artis'] ?? '';
    final coverUrl = _currentPlayingLagu?['cover_url'];

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
            ),
          ),
        ).then((_) => setState(() {})); 
      },
      child: Container(
        height: 65,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: coverUrl != null && coverUrl.toString().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _miniCoverFallback(),
                    )
                  : _miniCoverFallback(),
            ),
            const SizedBox(width: 12),
            // Info lagu
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
                      color: Colors.black87,
                    ),
                  ),
                  if (artis.isNotEmpty)
                    Text(
                      artis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            // Kontrol play/pause & stop
            StreamBuilder(
              stream: AudioManager.instance.player.playingStream,
              builder: (context, snapshot) {
                final playing = snapshot.data ?? false;
                return Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        playing
                            ? AudioManager.instance.player.pause()
                            : AudioManager.instance.player.play();
                        setState(() {});
                      },
                      icon: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await AudioManager.instance.player.stop();
                        AudioManager.instance.currentUrl = '';
                        setState(() => _currentPlayingLagu = null);
                      },
                      icon: const Icon(
                        Icons.stop_rounded,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _miniCoverFallback() {
    return Container(
      width: 65,
      height: 65,
      color: Colors.blue[100],
      child: const Icon(Icons.music_note_rounded, color: Colors.blue, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const MiniPlayerWidget(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pages_background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat Datang!',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(
                                  fontSize: 22,
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
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'logout') {
                            _logout();
                          } else if (value == 'edit_profil') {
                            final newUsername = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(builder: (_) => const EditProfilPage()),
                            );
                            if (newUsername != null) {
                              setState(() => username = newUsername);
                            }
                          }
                        },
                        offset: const Offset(0, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit_profil',
                            child: Row(
                              children: [
                                Icon(Icons.edit_rounded, color: Colors.blue),
                                SizedBox(width: 10),
                                Text('Edit Profil'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Logout', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Konten utama (scrollable) ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Label Fitur Utama ──
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Fitur Utama',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Grid 4 Fitur ──
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: features.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemBuilder: (context, index) {
                            final feature = features[index];
                            return GestureDetector(
                              onTap: () => _onFeatureTap(feature['label']),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      feature['icon'],
                                      size: 100,
                                      color: feature['color'],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      feature['label'],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Banner Lagu Pilihan Hari Ini ──
                        GestureDetector(
                          onTap: _onCeritaTap,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lagu Pilihan Hari Ini',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        featuredLagu != null
                                            ? featuredLagu!['judul'] ?? 'Memuat lagu...'
                                            : 'Memuat lagu...',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.play_circle_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Footer ──
                        Center(
                          child: Text(
                            '© 2026 Nada Cilik',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
}