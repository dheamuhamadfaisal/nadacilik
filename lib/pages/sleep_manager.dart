import 'dart:async';
import 'audio_manager.dart';

class SleepManager {
  SleepManager._();
  static final SleepManager instance = SleepManager._();

  Timer? countdownTimer;
  int sisaDetik = 0;
  bool aktif = false;
  int menitOtomatis = 30;
  bool _peringatanSudahTampil = false;

  final List<void Function()> _onTickListeners = [];
  final List<void Function()> _onWaktuHabisListeners = [];
  final List<void Function(int sisaDetik)> _onPeringatanListeners = [];

  void addOnTick(void Function() callback) => _onTickListeners.add(callback);
  void removeOnTick(void Function() callback) => _onTickListeners.remove(callback);

  void addOnWaktuHabis(void Function() callback) => _onWaktuHabisListeners.add(callback);
  void removeOnWaktuHabis(void Function() callback) => _onWaktuHabisListeners.remove(callback);

  void addOnPeringatan(void Function(int) callback) => _onPeringatanListeners.add(callback);
  void removeOnPeringatan(void Function(int) callback) => _onPeringatanListeners.remove(callback);

  void mulai(int menit) {
    aktif = true;
    menitOtomatis = menit;
    sisaDetik = menit * 60;
    _peringatanSudahTampil = false;
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      sisaDetik--;
      for (final cb in _onTickListeners) {
        cb();
      }

      if (sisaDetik == 10 && !_peringatanSudahTampil) {
        _peringatanSudahTampil = true;
        for (final cb in _onPeringatanListeners) {
          cb(sisaDetik);
        }
      }

      if (sisaDetik <= 0) {
        timer.cancel();
        aktif = false;
        AudioManager.instance.player.pause();

        for (final cb in _onWaktuHabisListeners) {
          cb();
        }
      }
    });
  }

  void berhenti() {
    countdownTimer?.cancel();
    countdownTimer = null;
    aktif = false;
    sisaDetik = 0;
    _peringatanSudahTampil = false;
  }
}