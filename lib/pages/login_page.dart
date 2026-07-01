import 'dart:async';
import 'package:flutter/material.dart';
import 'package:projectuas/snackbar/snackbar_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? usernameError;
  String? passwordError;
  String? confirmPasswordError;

  bool isLoading = false;
  bool isRegisterMode = false;

  static const _timeout = Duration(seconds: 10);

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _showNotif(String message, Color color) {
    if (!mounted) return;
    showTopNotif(context, message: message, backgroundColor: color);
  }

  // Fungsi Login
  Future<void> login() async {
    setState(() {
      usernameError = usernameController.text.isEmpty ? 'Username tidak boleh kosong' : null;
      passwordError = passwordController.text.isEmpty ? 'Password tidak boleh kosong' : null;
    });

    if (usernameError != null || passwordError != null) return;

    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text.trim())
          .where('password', isEqualTo: passwordController.text)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) {
        setState(() {
          usernameError = 'Akun tidak ditemukan, silahkan daftar terlebih dahulu';
          isLoading = false;
        });
        _showNotif('Akun tidak ditemukan! Silahkan daftar terlebih dahulu.', Colors.orange);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLogin', true);
      await prefs.setString('username', usernameController.text.trim());

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on TimeoutException {
      setState(() { usernameError = null; isLoading = false; });
      _showNotif('Koneksi timeout, coba lagi.', Colors.red);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error login: $e');
      setState(() { usernameError = null; isLoading = false; });
      _showNotif('Tidak ada koneksi internet!', Colors.red);
    } catch (e) {
      debugPrint('Error login: $e');
      setState(() { usernameError = 'Terjadi kesalahan. Coba lagi.'; isLoading = false; });
      _showNotif('Terjadi kesalahan. Coba lagi.', Colors.red);
    }
  }

  // Fungsi Register
  Future<void> register() async {
    setState(() {
      usernameError = usernameController.text.isEmpty ? 'Username tidak boleh kosong' : null;
      passwordError = passwordController.text.isEmpty ? 'Password tidak boleh kosong' : null;
      confirmPasswordError = confirmPasswordController.text.isEmpty
          ? 'Konfirmasi password tidak boleh kosong'
          : confirmPasswordController.text != passwordController.text
              ? 'Password tidak cocok'
              : null;
    });

    if (usernameError != null || passwordError != null || confirmPasswordError != null) return;

    setState(() => isLoading = true);

    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text.trim())
          .get()
          .timeout(_timeout);

      if (existing.docs.isNotEmpty) {
        setState(() { usernameError = 'Username sudah digunakan'; isLoading = false; });
        _showNotif('Username sudah digunakan, coba yang lain.', Colors.red);
        return;
      }

      await FirebaseFirestore.instance.collection('users').add({
        'username': usernameController.text.trim(),
        'password': passwordController.text,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(_timeout);

      if (!mounted) return;

      setState(() {
        isRegisterMode = false;
        isLoading = false;
        usernameController.clear();
        passwordController.clear();
        confirmPasswordController.clear();
      });

      _showNotif('Registrasi berhasil! Silakan login.', const Color.fromARGB(255, 39, 87, 217));
    } on TimeoutException {
      setState(() => isLoading = false);
      _showNotif('Koneksi timeout, coba lagi.', Colors.red);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error register: $e');
      setState(() => isLoading = false);
      _showNotif('Tidak ada koneksi internet!', Colors.red);
    } catch (e) {
      debugPrint('Error register: $e');
      setState(() { usernameError = 'Terjadi kesalahan. Coba lagi.'; isLoading = false; });
      _showNotif('Terjadi kesalahan. Coba lagi.', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_background.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(50),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Selamat Datang!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Serif',
                              color: const Color.fromARGB(255, 0, 0, 0),
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  blurRadius: 2.0,
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(1.0, 1.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isRegisterMode ? 'Buat akun baru' : 'Silakan masuk ke akun Anda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 25),

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
                          const SizedBox(height: 20),

                          // Password
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            onChanged: (_) {
                              if (passwordError != null) setState(() => passwordError = null);
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              errorText: passwordError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          // Konfirmasi Password
                          if (isRegisterMode) ...[
                            const SizedBox(height: 20),
                            TextField(
                              controller: confirmPasswordController,
                              obscureText: true,
                              onChanged: (_) {
                                if (confirmPasswordError != null) {
                                  setState(() => confirmPasswordError = null);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Konfirmasi Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                errorText: confirmPasswordError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 25),

                          // Tombol Login / Register
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : (isRegisterMode ? register : login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      isRegisterMode ? 'Daftar' : 'Login',
                                      style: const TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Toggle Login/Register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isRegisterMode ? 'Sudah punya akun? ' : 'Belum punya akun? ',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isRegisterMode = !isRegisterMode;
                                    usernameError = null;
                                    passwordError = null;
                                    confirmPasswordError = null;
                                    usernameController.clear();
                                    passwordController.clear();
                                    confirmPasswordController.clear();
                                  });
                                },
                                child: Text(
                                  isRegisterMode ? 'Login' : 'Daftar',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}