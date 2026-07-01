import 'package:projectuas/mini_player_widget.dart';
import 'package:projectuas/connection/connectivity_helper.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'package:projectuas/audio/audio_manager.dart';
import 'package:projectuas/sleep/sleep_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class SleepPage extends StatefulWidget {
  const SleepPage({super.key});

  @override
  State<SleepPage> createState() => _SleepPageState();
}

class _SleepPageState extends State<SleepPage> {
  late Timer _jamTimer;
  DateTime _now = DateTime.now();

  bool get _waktuTidurAktif => SleepManager.instance.aktif;
  int get _sisaDetik => SleepManager.instance.sisaDetik;
  int get _menitOtomatis => SleepManager.instance.menitOtomatis;

  @override
  void initState() {
    super.initState();

    _jamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    SleepManager.instance.addOnTick(_onTick);
    SleepManager.instance.addOnWaktuHabis(_onWaktuHabisLokal);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  void _onWaktuHabisLokal() {
    _tutupAplikasi();
  }

  @override
  void dispose() {
    _jamTimer.cancel();
    SleepManager.instance.removeOnTick(_onTick);
    SleepManager.instance.removeOnWaktuHabis(_onWaktuHabisLokal);
    super.dispose();
  }

  String _formatJam(DateTime dt) {
    final jam = dt.hour.toString().padLeft(2, '0');
    final menit = dt.minute.toString().padLeft(2, '0');
    return '$jam:$menit';
  }

  String _formatCountdown(int detik) {
    final m = (detik ~/ 60).toString().padLeft(2, '0');
    final s = (detik % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _toggleWaktuTidur(bool value) async {
    final adaKoneksi = await cekKoneksi();
    if (!adaKoneksi) {
      if (mounted) {
        showTopNotif(
          context,
          message: 'Tidak ada koneksi internet!',
          backgroundColor: Colors.red,
        );
        setState(() {});
      }
      return;
    }

    if (value) {
      SleepManager.instance.mulai(_menitOtomatis);
      setState(() {});
      showTopNotif(
        context,
        message: 'Waktu tidur aktif — tutup otomatis $_menitOtomatis menit lagi',
        backgroundColor: Colors.indigo,
      );
    } else {
      SleepManager.instance.berhenti();
      setState(() {});
      showTopNotif(
        context,
        message: 'Waktu tidur dimatikan',
        backgroundColor: Colors.grey,
      );
    }
  }

  Future<void> _tutupAplikasi() async {
    if (!mounted) return;

    await AudioManager.instance.player.stop();

    showTopNotif(
      context,
      message: 'Waktu habis! Sampai jumpa',
      backgroundColor: Colors.indigo,
      displayDuration: const Duration(seconds: 2),
    );

    await Future.delayed(const Duration(seconds: 2));
    SystemNavigator.pop();
  }

  void _pilihMenit() async {
    if (_waktuTidurAktif) {
      showTopNotif(
        context,
        message: 'Matikan waktu tidur dulu untuk mengubah durasi',
        backgroundColor: Colors.orange,
      );
      return;
    }

    final pilihan = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Matikan otomatis setelah'),
        children: [
          ...[15, 30, 45, 60].map((menit) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, menit),
              child: Text('$menit menit'),
            );
          }),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, -10),
            child: const Text('10 detik (testing)'),
          ),
        ],
      ),
    );

    if (pilihan != null) {
      if (pilihan == -10) {
        SleepManager.instance.mulaiDenganDetik(10);
        setState(() {});
        showTopNotif(
          context,
          message: 'Waktu tidur aktif — tutup otomatis 10 detik lagi (testing)',
          backgroundColor: Colors.indigo,
        );
      } else {
        SleepManager.instance.menitOtomatis = pilihan;
        setState(() {});
      }
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
            image: AssetImage('assets/images/sleep_background.jpeg'),
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
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                      ),
                      const Text(
                        'Pengaturan Tidur',
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
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 32, horizontal: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _formatJam(_now),
                                style: const TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Waktu Tidur Sekarang',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                              if (_waktuTidurAktif) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer_rounded,
                                          color: Colors.white70, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tutup dalam ${_formatCountdown(_sisaDetik)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures: [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.alarm_rounded,
                                color: Colors.orange,
                                size: 28,
                              ),
                            ),
                            title: const Text(
                              'Waktu Tidur',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: GestureDetector(
                              onTap: _pilihMenit,
                              child: Text(
                                _waktuTidurAktif
                                    ? 'Sisa: ${_formatCountdown(_sisaDetik)} — Tap untuk ubah'
                                    : 'Matikan Otomatis: $_menitOtomatis menit — Tap untuk ubah',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _waktuTidurAktif
                                      ? Colors.indigo
                                      : Colors.grey[600],
                                  fontWeight: _waktuTidurAktif
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            trailing: Switch(
                              value: _waktuTidurAktif,
                              onChanged: _toggleWaktuTidur,
                              activeColor: Colors.indigo,
                            ),
                          ),
                        ),
                        const Spacer(),
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