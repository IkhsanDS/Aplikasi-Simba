import 'package:flutter/material.dart';
import 'monitoring_page.dart';

class AccessCodePage extends StatefulWidget {
  const AccessCodePage({super.key});

  @override
  State<AccessCodePage> createState() => _AccessCodePageState();
}

class _AccessCodePageState extends State<AccessCodePage> {
  final TextEditingController _controller = TextEditingController();
  final String _correctCode = "1234";
  String _errorMessage = "";

  void _verifyCode() {
    if (_controller.text == _correctCode) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => MonitoringPage(
                toggleTheme:
                    () {}, // kosong dulu atau isi dengan fungsi sesuai kebutuhan
              ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = "Kode salah, coba lagi!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/logo2.png', width: 100, height: 100),
              const SizedBox(height: 20),

              // 🟦 Judul Aplikasi
              const Text(
                "SIMBA",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              const SizedBox(height: 32),

              // 🟧 Teks Masukkan Kode
              const Text(
                "Masukkan Kode Akses",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // 🔐 Input Field
              TextField(
                controller: _controller,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                ), // 🔵 Ubah warna teks input
                decoration: InputDecoration(
                  labelText: "Kode Akses",
                  labelStyle: const TextStyle(
                    color: Colors.white,
                  ), // 🔵 Warna label
                  errorText: _errorMessage.isEmpty ? null : _errorMessage,
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _verifyCode,
                child: const Text("Masuk"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
