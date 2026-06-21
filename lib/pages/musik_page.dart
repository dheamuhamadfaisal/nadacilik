import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/pages/snackbar_helper.dart';
import 'player_page.dart';

class MusikPage extends StatefulWidget {
  const MusikPage({super.key});

  @override
  State<MusikPage> createState() => _MusikPageState();
}

class _MusikPageState extends State<MusikPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allLagu = [];
  List<Map<String, dynamic>> filteredLagu = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLagu();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLagu() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lagu')
          .get();

      final filtered = snapshot.docs
          .where((doc) => doc.data()['tipe'] == 'musik')
          .map((doc) => doc.data())
          .toList();

      setState(() {
        allLagu = filtered;
        filteredLagu = List.from(allLagu);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching lagu: $e');
      setState(() => isLoading = false);
      if (mounted) {
        showTopNotif(
          context,
          message: 'Gagal memuat lagu. Coba lagi nanti.',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      filteredLagu = allLagu
          .where((lagu) =>
              lagu['judul']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              lagu['artis']
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _onTambah(Map<String, dynamic> lagu) async {
    try {
      final existing = await FirebaseFirestore.instance
          .collection('favorit')
          .where('judul', isEqualTo: lagu['judul'])
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          showTopNotif(
            context,
            message: '${lagu['judul']} sudah ada di Favorit!',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('favorit')
          .add(lagu);

      if (mounted) {
        showTopNotif(
          context,
          message: '${lagu['judul']} ditambahkan ke Favorit!',
          backgroundColor: const Color.fromARGB(255, 39, 87, 217),
        );
      }
    } catch (e) {
      debugPrint('Error tambah favorit: $e');
      if (mounted) {
        showTopNotif(
          context,
          message: 'Gagal menambahkan ke Favorit.',
          backgroundColor: Colors.red,
        );
      }
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                      const Text(
                        'Musik',
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
                        hintText: 'Cari musik...',
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

                // ── List Lagu ──
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : filteredLagu.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.music_off_rounded,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada lagu tersedia',
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
                              itemCount: filteredLagu.length,
                              itemBuilder: (context, index) {
                                final lagu = filteredLagu[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.92),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.07),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlayerPage(
                                          judul: lagu['judul'] ?? '',
                                          artis: lagu['artis'] ?? '',
                                          audioUrl: lagu['audio_url'] ?? '',
                                          coverUrl: lagu['cover_url'],
                                          playlist: filteredLagu,
                                          currentIndex: index,
                                        ),
                                      ),
                                    ),
                                    leading: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlue[100],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: lagu['cover_url'] != null &&
                                                lagu['cover_url'].toString().isNotEmpty
                                            ? CachedNetworkImage(
                                                imageUrl: lagu['cover_url'],
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => Container(
                                                  color: Colors.lightBlue[100],
                                                  child: const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.lightBlue,
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    Container(
                                                  color: Colors.lightBlue[100],
                                                  child: const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.lightBlue,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.lightBlue[100],
                                                child: const Icon(
                                                  Icons.music_note_rounded,
                                                  color: Colors.lightBlue,
                                                ),
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      lagu['judul'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      lagu['artis'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: IconButton(
                                      onPressed: () => _onTambah(lagu),
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: Colors.lightBlue,
                                        size: 28,
                                      ),
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
}