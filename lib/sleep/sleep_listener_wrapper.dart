import 'package:flutter/material.dart';
import 'sleep_manager.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';

class SleepListenerWrapper extends StatefulWidget {
  final Widget child;
  const SleepListenerWrapper({super.key, required this.child});

  @override
  State<SleepListenerWrapper> createState() => _SleepListenerWrapperState();
}

class _SleepListenerWrapperState extends State<SleepListenerWrapper> {
  void _onPeringatan(int sisaDetik) {
    if (mounted) {
      showTopNotif(
        context,
        message: 'Waktu tidur akan habis dalam $sisaDetik detik!',
        backgroundColor: Colors.orange,
        displayDuration: const Duration(seconds: 3),
      );
    }
  }

  void _onWaktuHabis() {
    if (mounted) {
      showTopNotif(
        context,
        message: 'Waktu tidur habis, musik dihentikan',
        backgroundColor: Colors.indigo,
        displayDuration: const Duration(seconds: 3),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    SleepManager.instance.addOnPeringatan(_onPeringatan);
    SleepManager.instance.addOnWaktuHabis(_onWaktuHabis);
  }

  @override
  void dispose() {
    SleepManager.instance.removeOnPeringatan(_onPeringatan);
    SleepManager.instance.removeOnWaktuHabis(_onWaktuHabis);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}