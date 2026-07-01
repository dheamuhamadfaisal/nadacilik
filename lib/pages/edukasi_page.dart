import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectuas/mini_player_widget.dart';
import 'package:projectuas/audio/audio_manager.dart';

class EdukasiPage extends StatefulWidget {
  const EdukasiPage({super.key});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allLagu = [];
  List<Map<String, dynamic>> filteredLagu = [];
  Set<String> _judulFavorit = {};
  bool isLoading = true;
  static const _timeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('lagu')
            .where('tipe', isEqualTo: 'edukasi')
            .get()
            .timeout(_timeout),
        FirebaseFirestore.instance
            .collection('favorit')
            .get()
            .timeout(_timeout),
      ]);

      final laguList = results[0].docs.map((doc) => doc.data()).toList();
      final judulFavSet = results[1].docs
          .map((doc) => doc.data()['judul']?.toString() ?? '')
          .toSet();

      if (mounted) {
        setState(() {
          allLagu = laguList;
          filteredLagu = List.from(allLagu);
          _judulFavorit = judulFavSet;
          isLoading = false;
        });
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(context, message: 'Koneksi timeout, coba lagi.', backgroundColor: Colors.red);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(context, message: 'Tidak ada koneksi internet!', backgroundColor: Colors.red);
      }
    } catch (e) {
      debugPrint('Error fetching lagu: $e');
      if (mounted) {
        setState(() => isLoading = false);
        showTopNotif(context, message: 'Gagal memuat lagu. Coba lagi nanti.', backgroundColor: Colors.redAccent);
      }
    }
  }

  void _onSearch(String query) {
    setState(() {
      filteredLagu = query.isEmpty
          ? List.from(allLagu)
          : allLagu.where((lagu) {
              final q = query.toLowerCase();
              return lagu['judul'].toString().toLowerCase().contains(q) ||
                  lagu['artis'].toString().toLowerCase().contains(q);
            }).toList();
    });
  }

  Future<void> _onTambah(Map<String, dynamic> lagu) async {
    final judul = lagu['judul']?.toString() ?? '';
    final artis = lagu['artis']?.toString() ?? '';

    if (_judulFavorit.contains(judul)) {
      showTopNotif(context, message: '$judul sudah ada di Favorit!', backgroundColor: Colors.orange);
      return;
    }

    final konfirmasi = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: Colors.blue, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Tambah ke Favorit?', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 8),
              Text(judul, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              const SizedBox(height: 4),
              Text(artis, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Batal',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tambahkan',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (konfirmasi != true) return;

    try {
      await FirebaseFirestore.instance.collection('favorit').add(lagu).timeout(_timeout);
      setState(() => _judulFavorit.add(judul));
      if (mounted) {
        showTopNotif(context, message: '✓ $judul ditambahkan ke Favorit!', backgroundColor: Colors.blue);
      }
    } on TimeoutException {
      if (mounted) showTopNotif(context, message: 'Koneksi timeout, coba lagi.', backgroundColor: Colors.red);
    } catch (e) {
      debugPrint('Error tambah favorit: $e');
      if (mounted) showTopNotif(context, message: 'Gagal menambahkan ke Favorit.', backgroundColor: Colors.red);
    }
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const Text('Edukasi', style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(1, 1))],
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Cari lagu edukasi...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : filteredLagu.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.music_off_rounded, size: 60, color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(height: 12),
                                  Text('Belum ada lagu edukasi',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchAll,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                itemCount: filteredLagu.length,
                                itemBuilder: (context, index) {
                                  final lagu = filteredLagu[index];
                                  final sudahFavorit = _judulFavorit.contains(lagu['judul']?.toString() ?? '');
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.92),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))],
                                    ),
                                    child: ListTile(
                                      onTap: () => AudioManager.instance.playLagu(
                                        judul: lagu['judul'] ?? '',
                                        artis: lagu['artis'] ?? '',
                                        audioUrl: lagu['audio_url'] ?? '',
                                        coverUrl: lagu['cover_url'],
                                        playlist: filteredLagu,
                                        index: index,
                                      ),
                                      leading: Container(
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(10)),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: lagu['cover_url'] != null && lagu['cover_url'].toString().isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: lagu['cover_url'], fit: BoxFit.cover,
                                                  placeholder: (_, __) => Container(color: Colors.orange[100], child: const Icon(Icons.music_note_rounded, color: Colors.orange)),
                                                  errorWidget: (_, __, ___) => Container(color: Colors.orange[100], child: const Icon(Icons.music_note_rounded, color: Colors.orange)),
                                                )
                                              : Container(color: Colors.orange[100], child: const Icon(Icons.music_note_rounded, color: Colors.orange)),
                                        ),
                                      ),
                                      title: Text(lagu['judul'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      subtitle: Text(lagu['artis'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      trailing: IconButton(
                                        onPressed: sudahFavorit ? null : () => _onTambah(lagu),
                                        icon: Icon(
                                          sudahFavorit ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                          color: sudahFavorit ? Colors.green : Colors.orange,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  );
                                },
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