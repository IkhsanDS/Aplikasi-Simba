import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:SIMBA/Screen/access_code_page.dart';

class MonitoringPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const MonitoringPage({super.key, required this.toggleTheme});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref("data");
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _previousStatusAir;
  String? _previousStatusTinggiAir;
  Map<String, dynamic> _localData = {};
  int _currentIndex = 0;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadLocalData();

    _ref.onValue.listen((event) async {
      final dataSnapshot = event.snapshot;
      if (dataSnapshot.exists) {
        final data = Map<String, dynamic>.from(dataSnapshot.value as Map);

        await _saveLocalData(data);

        setState(() {
          _localData = data;
          _lastUpdate = DateTime.now();
        });

        final currentStatusAir =
            data['status_air']?.toString() ?? "Tidak diketahui";
        final currentTinggiAir =
            data['tinggi_air']?.toString() ?? "Tidak diketahui";
        final jarak =
            data['jarak']?.toString() ?? "Tidak diketahui";

        final now = DateTime.now();
        final formattedTime =
            "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

        final message =
            "🕒 $formattedTime\nStatus Air: $currentStatusAir\n"
            "Status Tinggi Air: $currentTinggiAir\nJarak: $jarak";

        if ((_previousStatusAir != currentStatusAir ||
                _previousStatusTinggiAir != currentTinggiAir) &&
            (currentStatusAir == "WASPADA" || currentStatusAir == "BAHAYA")) {
          _previousStatusAir = currentStatusAir;
          _previousStatusTinggiAir = currentTinggiAir;

          _showNotification(
            "🚨 Status Air: $currentStatusAir",
            message,
            withCustomSound: true,
          );
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("⚠️ Peringatan"),
                  content: Text(
                    "Status Air   : $currentStatusAir\n"
                    "Tinggi air   : $currentTinggiAir\n"
                    "Jarak        : $jarak",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    });
  }

  Future<void> _saveLocalData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      'kelembapan',
      double.tryParse(data['kelembapan']?.toString() ?? '') ?? 0.0,
    );
    await prefs.setDouble(
      'nilai_hujan',
      double.tryParse(data['nilai_hujan']?.toString() ?? '') ?? 0.0,
    );
    await prefs.setString(
      'prediksi_cuaca',
      data['prediksi_cuaca']?.toString() ?? 'Menunggu...',
    );
    await prefs.setDouble(
      'suhu',
      double.tryParse(data['suhu']?.toString() ?? '') ?? 0.0,
    );
    await prefs.setString(
      'status_air',
      data['status_air']?.toString() ?? 'Menunggu...',
    );
    await prefs.setString(
      'status_hujan',
      data['status_hujan']?.toString() ?? 'Menunggu...',
    );
    await prefs.setDouble(
      'tekanan',
      double.tryParse(data['tekanan']?.toString() ?? '') ?? 0.0,
    );
    await prefs.setDouble(
      'jarak',
      double.tryParse(data['jarak']?.toString() ?? '') ?? 0.0,
    );
    await prefs.setDouble(
      'tinggi_air',
      double.tryParse(data['tinggi_air']?.toString() ?? '') ?? 0.0,
    );
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localData = {
        'kelembapan': prefs.getDouble('kelembapan') ?? 0.0,
        'nilai_hujan': prefs.getDouble('nilai_hujan') ?? 0.0,
        'prediksi_cuaca': prefs.getString('prediksi_cuaca') ?? 'Menunggu...',
        'suhu': prefs.getDouble('suhu') ?? 0.0,
        'status_air': prefs.getString('status_air') ?? 'Menunggu...',
        'status_hujan': prefs.getString('status_hujan') ?? 'Menunggu...',
        'tekanan': prefs.getDouble('tekanan') ?? 0.0,
        'jarak': prefs.getDouble('jarak') ?? 0.0,
        'tinggi_air': prefs.getDouble('tinggi_air') ?? 0.0,
      };
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 🔥 Tambahkan channel notifikasi custom di sini
    const AndroidNotificationChannel
    customSoundChannel = AndroidNotificationChannel(
      'custom_sound_channel', // <- ID ini harus sama dengan yang di AndroidNotificationDetails
      'Channel with Custom Sound',
      description: 'Digunakan untuk peringatan banjir dengan suara khusus',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('bahaya'), // file: bahaya.mp3
      playSound: true,
    );

    // Mendaftarkan channel ke Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(customSoundChannel);

    // 🔔 Izin notifikasi FCM (Firebase Cloud Messaging)
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'custom_sound_channel', // channel harus cocok
                'Channel with Custom Sound',
                importance: Importance.max,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound('bahaya'),
                playSound: true,
              ),
            ),
          );
        }
      });
    }
  }

  Future<void> _showNotification(
    String title,
    String body, {
    bool withCustomSound = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'custom_sound_channel',
      'Channel with Custom Sound',
      importance: Importance.max,
      priority: Priority.high,
      sound:
          withCustomSound
              ? const RawResourceAndroidNotificationSound('bahaya')
              : null,
      playSound: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  Widget _buildDataCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataColumn(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _monitoringView() {
    final data = _localData;

    return data.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Banner atas: Status Air, Jarak, Hasil
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDataColumn(
                            "Status Air",
                            data['status_air'].toString(),
                            Icons.warning,
                            Colors.redAccent,
                          ),
                          _buildDataColumn(
                            "Jarak",
                            "${data['jarak']} cm",
                            Icons.straighten,
                            Colors.green,
                          ),
                          _buildDataColumn(
                            "tinggi_air",
                            "${data['tinggi_air']}",
                            Icons.bar_chart,
                            Colors.pink,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kotak Nilai Hujan dan Status Hujan
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDataColumn(
                            "Nilai Hujan",
                            "${data['nilai_hujan']}",
                            Icons.grain,
                            Colors.indigo,
                          ),
                          _buildDataColumn(
                            "Status Hujan",
                            data['status_hujan'].toString(),
                            Icons.umbrella,
                            Colors.cyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sisanya tetap grid
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildDataCard(
                    "Suhu",
                    "${data['suhu']} °C",
                    Icons.thermostat,
                    Colors.orange,
                  ),
                  _buildDataCard(
                    "Kelembapan",
                    "${data['kelembapan']}%",
                    Icons.water_drop,
                    Colors.blue,
                  ),
                  _buildDataCard(
                    "Tekanan",
                    "${data['tekanan']} hPa",
                    Icons.compress,
                    Colors.teal,
                  ),
                  _buildDataCard(
                    "Prediksi Cuaca",
                    "${data['prediksi_cuaca']}",
                    Icons.cloud,
                    Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              Align(
                alignment: Alignment.center,
                child: Text(
                  "Terakhir diperbarui: ${_lastUpdate != null ? _lastUpdate!.toLocal().toString().split('.')[0] : '-'}",
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
  }

  Widget _aboutView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Tentang Aplikasi Monitoring Banjir",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            "Aplikasi ini digunakan untuk memantau kondisi banjir secara real-time menggunakan sensor yang terhubung dengan Firebase Realtime Database. "
            "Anda dapat melihat data seperti suhu, kelembapan, tekanan udara, dan status air secara langsung di aplikasi ini. "
            "Notifikasi otomatis akan memberitahu Anda jika terjadi perubahan penting pada status banjir.",
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            "Projek ini untuk memenuhi skripsi saya.",
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [_monitoringView(), _aboutView()];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Monitoring Banjir"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove("status");
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MonitoringPage(toggleTheme: widget.toggleTheme)),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: "Tentang"),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
