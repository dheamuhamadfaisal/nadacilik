import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:async';

Future<bool> cekKoneksi() async {
  // Di Flutter Web, selalu anggap ada koneksi
  if (kIsWeb) return true;

  // Step 1: Cek apakah ada interface koneksi aktif
  // checkConnectivity() sekarang return List<ConnectivityResult>
  final results = await Connectivity().checkConnectivity();
  final tidakAdaKoneksi = results.isEmpty || 
      results.every((r) => r == ConnectivityResult.none);
  if (tidakAdaKoneksi) return false;

  // Step 2: Verifikasi internet benar-benar bisa diakses
  try {
    final lookupResult = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));

    return lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
  } on SocketException catch (_) {
    return false;
  } on TimeoutException catch (_) {
    return false;
  } catch (_) {
    return false;
  }
}