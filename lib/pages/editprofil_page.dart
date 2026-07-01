import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';

class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? usernameError;
  String? passwordError;
  String? confirmPasswordError;
  bool isLoading = false;
  String oldUsername = '';

  static const _timeout = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('username') ?? '';
    if (mounted) {
      setState(() {
        oldUsername = saved;
        usernameController.text = saved;
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    final newUsername = usernameController.text.trim();
    final newPassword = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    setState(() {
      usernameError = newUsername.isEmpty ? 'Username tidak boleh kosong' : null;
      passwordError = null;
      confirmPasswordError = null;

      if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
        if (newPassword.isEmpty) {
          passwordError = 'Password tidak boleh kosong';
        } else if (confirmPassword != newPassword) {
          confirmPasswordError = 'Password tidak cocok';
        }
      }
    });

    if (usernameError != null || passwordError != null || confirmPasswordError != null) return;

    final passwordTidakDiubah = newPassword.isEmpty;
    if (newUsername == oldUsername && passwordTidakDiubah) {
      showTopNotif(context, message: 'Tidak ada perubahan');
      return;
    }

    setState(() => isLoading = true);

    try {
      final Future<QuerySnapshot> snapshotFuture = FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: oldUsername)
          .get()
          .timeout(_timeout);

      final Future<QuerySnapshot>? existingFuture = newUsername != oldUsername
          ? FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: newUsername)
              .get()
              .timeout(_timeout)
          : null;

      final results = await Future.wait([
        snapshotFuture,
        if (existingFuture != null) existingFuture,
      ]);

      final snapshot = results[0];
      final existing = existingFuture != null ? results[1] : null;

      if (snapshot.docs.isEmpty) {
        setState(() { usernameError = 'Akun tidak ditemukan'; isLoading = false; });
        return;
      }

      if (existing != null && existing.docs.isNotEmpty) {
        setState(() { usernameError = 'Username sudah digunakan'; isLoading = false; });
        showTopNotif(context, message: 'Username sudah digunakan', backgroundColor: Colors.red);
        return;
      }

      final docRef = snapshot.docs.first.reference;
      final Map<String, dynamic> updateData = {'username': newUsername};
      if (newPassword.isNotEmpty) updateData['password'] = newPassword;

      await docRef.update(updateData).timeout(_timeout);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', newUsername);

      if (!mounted) return;

      showTopNotif(context, message: 'Profil berhasil diperbarui');
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pop(context, newUsername);
    } on TimeoutException {
      if (!mounted) return;
      setState(() => isLoading = false);
      showTopNotif(context, message: 'Koneksi timeout, coba lagi.', backgroundColor: Colors.red);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      showTopNotif(context, message: 'Tidak ada koneksi internet!', backgroundColor: Colors.red);
    } catch (e) {
      debugPrint('Error update profil: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
      showTopNotif(context, message: 'Terjadi kesalahan. Coba lagi.', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/pages_background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.1),
          child: SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                      ),
                      const Text(
                        'Edit Profil',
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

                // Form
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(25),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.blue[100],
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Perbarui informasi akunmu',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),

                                // Username
                                TextField(
                                  controller: usernameController,
                                  onChanged: (_) {
                                    if (usernameError != null) setState(() => usernameError = null);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: const Icon(Icons.person),
                                    errorText: usernameError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password Baru
                                TextField(
                                  controller: passwordController,
                                  obscureText: true,
                                  onChanged: (_) {
                                    if (passwordError != null) setState(() => passwordError = null);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password Baru (opsional)',
                                    prefixIcon: const Icon(Icons.lock),
                                    errorText: passwordError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Konfirmasi Password
                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  onChanged: (_) {
                                    if (confirmPasswordError != null) {
                                      setState(() => confirmPasswordError = null);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Konfirmasi Password Baru',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    errorText: confirmPasswordError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Tombol Simpan
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : _simpan,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'Simpan Perubahan',
                                            style: TextStyle(fontSize: 16, color: Colors.white),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Tombol Batal
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: isLoading ? null : () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(255, 230, 4, 4),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(fontSize: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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