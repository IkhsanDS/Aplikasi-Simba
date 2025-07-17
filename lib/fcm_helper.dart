import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> kirimStatusKeBackend(String status, String token) async {
  final url = Uri.parse('http://localhost:3000/send-alert'); // ganti 'localhost' jika di Android emulator

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "status": status,
        "token": "cS12UGIJScqbW9hsCQWXC_:APA91bHIY1iOUSTPhHzYE4xVB29m4ri8X1E0zX9eXZxAc5jJNPwsMeQaG3WiYJkuFFhOxKzyegqd83Nor9ICkuyqVhvOiGgmfxKXhK2vgTrjEOu5ohsxUKk"
      // ini token FCM user
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Notifikasi berhasil dikirim!");
    } else {
      print("❌ Gagal kirim notifikasi: ${response.body}");
    }
  } catch (e) {
    print("🚨 Error kirim ke backend: $e");
  }
}
