import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:projectuas/audio/audio_manager.dart';

class SleepManager {
  SleepManager._();
  static final SleepManager instance = SleepManager._();

  Timer? countdownTimer;
  int sisaDetik = 0;
  bool aktif = false;
  int menitOtomatis = 30;

  //Listeners untuk update UI
  final List<VoidCallback> _onTickListeners = [];
  final List<VoidCallback> _onWaktuHabisListeners = [];
  final List<void Function(int)> _onPeringatanListeners = []; // ← tambah

  void addOnTick(VoidCallback cb) => _onTickListeners.add(cb);
  void removeOnTick(VoidCallback cb) => _onTickListeners.remove(cb);

  void addOnWaktuHabis(VoidCallback cb) => _onWaktuHabisListeners.add(cb);
  void removeOnWaktuHabis(VoidCallback cb) => _onWaktuHabisListeners.remove(cb);

  //Tambah support onPeringatan
  void addOnPeringatan(void Function(int sisaDetik) cb) => _onPeringatanListeners.add(cb);
  void removeOnPeringatan(void Function(int sisaDetik) cb) => _onPeringatanListeners.remove(cb);

  void mulai(int menit) {
    aktif = true;
    menitOtomatis = menit;
    sisaDetik = menit * 60;
    _startTimer();
  }

  void mulaiDenganDetik(int detik) {
    aktif = true;
    sisaDetik = detik;
    _startTimer();
  }

  void _startTimer() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sisaDetik--;

      //Update UI setiap detik
      for (final cb in List.of(_onTickListeners)) {
        cb();
      }

      //Kirim peringatan saat sisa 30 detik dan 10 detik
      if (sisaDetik == 30 || sisaDetik == 10) {
        for (final cb in List.of(_onPeringatanListeners)) {
          cb(sisaDetik);
        }
      }

      if (sisaDetik <= 0) {
        timer.cancel();
        aktif = false;

        // ✅ Notify listeners waktu habis
        for (final cb in List.of(_onWaktuHabisListeners)) {
          cb();
        }

        //Tutup aplikasi langsung dari singleton
        Future.delayed(const Duration(seconds: 2), () async {
          await AudioManager.instance.player.stop();
          SystemNavigator.pop();
        });
      }
    });
  }

  void berhenti() {
    countdownTimer?.cancel();
    countdownTimer = null;
    aktif = false;
    sisaDetik = 0;
  }
}