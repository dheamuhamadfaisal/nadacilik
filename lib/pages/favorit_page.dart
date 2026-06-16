import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/pages/snackbar_helper.dart';
import 'player_page.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
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
          .collection('favorit')
          .get();

      setState(() {
        allLagu = snapshot.docs.map((doc) {
          return {
            ...doc.data(),
            'doc_id': doc.id,
          };
        }).toList();
        filteredLagu = List.from(allLagu);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching favorit: $e');
      setState(() => isLoading = false);
      if (mounted) {
        // ✅ Ganti ScaffoldMessenger dengan showTopNotif
        showTopNotif(
          context,
          message: 'Gagal memuat favorit. Coba lagi nanti.',
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

  Future<void> _onHapus(Map<String, dynamic> lagu) async {
    try {
      await FirebaseFirestore.instance
          .collection('favorit')
          .doc(lagu['doc_id'])
          .delete();

      setState(() {
        allLagu.removeWhere((l) => l['doc_id'] == lagu['doc_id']);
        filteredLagu.removeWhere((l) => l['doc_id'] == lagu['doc_id']);
      });

      if (mounted) {
        showTopNotif(
          context,
          message: '${lagu['judul']} dihapus dari Favorit!',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      debugPrint('Error hapus favorit: $e');
      if (mounted) {
        showTopNotif(
          context,
          message: 'Gagal menghapus dari Favorit.',
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
            image: AssetImage('assets/images/favorite_background.jpeg'),
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
                        'Favorit',
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
                        hintText: 'Apa lagu yang ingin anak cari?',
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
                                  Icon(Icons.star_outline_rounded,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Belum ada lagu favorit',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tambahkan lagu dari Musik atau Edukasi',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
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
                                        color: Colors.blue[100],
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
                                                  color: Colors.blue[100],
                                                  child: const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                errorWidget: (context, url, error) =>
                                                    Container(
                                                  color: Colors.blue[100],
                                                  child: const Icon(
                                                    Icons.music_note_rounded,
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.blue[100],
                                                child: const Icon(
                                                  Icons.music_note_rounded,
                                                  color: Colors.blue,
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
                                      onPressed: () => _onHapus(lagu),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.red,
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