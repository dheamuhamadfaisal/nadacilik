import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/connection/connectivity_helper.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'player_page.dart';

class CeritaPage extends StatefulWidget {
  const CeritaPage({super.key});

  @override
  State<CeritaPage> createState() => _CeritaPageState();
}

class _CeritaPageState extends State<CeritaPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allCerita = [];
  List<Map<String, dynamic>> filteredCerita = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCerita();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCerita() async {
    final adaKoneksi = await cekKoneksi();
    if (!adaKoneksi){
      if(mounted){
        showTopNotif(
          context, 
          message: 'Tidak Ada Koneksi Internet!',
        );
      }
      return;
    }

    setState(() => isLoading = true);

    // TODO: ganti dengan API call, contoh:
    // final response = await http.get(Uri.parse('https://api-kamu.com/cerita'));
    // final data = jsonDecode(response.body) as List;
    // allCerita = data.map((e) => e as Map<String, dynamic>).toList();

    await Future.delayed(const Duration(seconds: 1));
    allCerita = [];

    setState(() {
      filteredCerita = List.from(allCerita);
      isLoading = false;
    });
  }

  void _onSearch(String query) {
    setState(() {
      filteredCerita = allCerita
          .where((cerita) => cerita['judul']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onCeritaTap(Map<String, dynamic> cerita) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          judul: cerita['judul'] ?? '',
          artis: cerita['penulis'] ?? 'Nada Cilik',
          audioUrl: cerita['audio_url'] ?? '',
          coverUrl: cerita['cover_url'],
        ),
      ),
    );
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                      const Text(
                        'Cerita Hari Ini',
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

                const SizedBox(height: 12),

                // ── Search Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Cari cerita...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── List Cerita ──
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : filteredCerita.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.menu_book_rounded,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada cerita tersedia',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 4),
                              itemCount: filteredCerita.length,
                              itemBuilder: (context, index) {
                                final cerita = filteredCerita[index];
                                return GestureDetector(
                                  onTap: () => _onCeritaTap(cerita),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.07),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [

                                        // Cover cerita
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(14),
                                            bottomLeft: Radius.circular(14),
                                          ),
                                          child: cerita['cover_url'] != null
                                              ? CachedNetworkImage(
                                                  imageUrl: cerita['cover_url'],
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                  placeholder: (ctx, url) =>
                                                      Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.purple[50],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (ctx, url, error) =>
                                                          _coverFallback(),
                                                )
                                              : _coverFallback(),
                                        ),

                                        const SizedBox(width: 12),

                                        // Info cerita
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  cerita['judul'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  cerita['penulis'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Tombol play
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 12),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.purple[100],
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.purple,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
      width: 80,
      height: 80,
      color: Colors.purple[50],
      child: const Icon(
        Icons.menu_book_rounded,
        size: 36,
        color: Colors.purple,
      ),
    );
  }
}