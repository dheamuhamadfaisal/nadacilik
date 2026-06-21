import 'dart:async';
import 'package:flutter/foundation.dart';

class SleepManager {
  SleepManager._();
  static final SleepManager instance = SleepManager._();

  Timer? countdownTimer;
  int sisaDetik = 0;
  bool aktif = false;
  int menitOtomatis = 30;

  VoidCallback? onWaktuHabis;
  VoidCallback? onTick;

  void mulai(int menit) {
    aktif = true;
    menitOtomatis = menit;
    sisaDetik = menit * 60;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sisaDetik--;
      onTick?.call();
      if (sisaDetik <= 0) {
        timer.cancel();
        aktif = false;
        onWaktuHabis?.call();
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