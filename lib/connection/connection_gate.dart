// Penjaga gerbang sebelum user bisa masuk ke halaman utama aplikasi.

import 'package:flutter/material.dart';
import 'package:projectuas/pages/no_connection_page.dart';
import 'package:projectuas/connection/connectivity_helper.dart'; // file tempat cekKoneksi() berada
// import halaman tujuan, misal login_page.dart atau splash kamu

class ConnectionGate extends StatefulWidget {
  final Widget child; // halaman yang dituju kalau koneksi ada
  const ConnectionGate({super.key, required this.child});

  @override
  State<ConnectionGate> createState() => _ConnectionGateState();
}

class _ConnectionGateState extends State<ConnectionGate> {
  bool? _terhubung;

  @override
  void initState() {
    super.initState();
    _cek();
  }

  Future<void> _cek() async {
    setState(() => _terhubung = null); // tampilkan loading saat re-check
    final hasil = await cekKoneksi();
    setState(() => _terhubung = hasil);
  }

  @override
  Widget build(BuildContext context) {
    if (_terhubung == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_terhubung == false) {
      return NoConnectionPage(onRetry: _cek);
    }
    return widget.child;
  }
}