# Panduan Implementasi MQTT Service dengan WebSocket di Flutter

Dokumen ini menjelaskan langkah-langkah lengkap untuk membuat layanan MQTT yang menggunakan protokol WebSocket, yang berguna untuk koneksi realtime yang efisien, terutama di lingkungan web atau jaringan yang membatasi port TCP biasa.

## 1. Persiapan Dependensi

Pertama, tambahkan paket `mqtt_client` ke dalam file `pubspec.yaml`. Paket ini adalah standar de-facto untuk Flutter.

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... dependensi lainnya
  mqtt_client: ^10.0.0 # Cek versi terbaru di pub.dev
```

Jangan lupa jalankan `flutter pub get` di terminal.

## 2. Struktur Kode MQTT Service

Kami menyarankan membuat file terpisah, misalnya `lib/core/services/mqtt_service.dart`, untuk menangani semua logika koneksi.

Berikut adalah contoh implementasi lengkap untuk koneksi **WebSocket Secure (WSS)**:

```dart
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart'; // Untuk TCP biasa
import 'package:mqtt_client/mqtt_browser_client.dart'; // KHUSUS WEB
// Catatan: Untuk support cross-platform (Mobile + Web), gunakan conditional import atau mqtt_client universal.
// Contoh di bawah menggunakan MqttServerClient yang umum untuk Mobile (Android/iOS).
// Untuk WebSocket di Mobile, kita tetap bisa pakai MqttServerClient dengan konfigurasi khusus.

class MqttService {
  late MqttServerClient client;

  // Konfigurasi Broker
  final String broker = 'broker.hivemq.com';
  final int port = 8000; // Port WebSocket HiveMQ (bukan 1883)
  final String clientIdentifier = 'flutter_client_id_123';

  Future<void> connect() async {
    // 1. Inisialisasi Client
    client = MqttServerClient.withPort(broker, clientIdentifier, port);

    // 2. Konfigurasi WebSocket
    client.useWebSocket = true; // Wajib true untuk WS
    client.secure = false; // Set true jika menggunakan WSS (SSL)
    // client.securityContext = SecurityContext.defaultContext; // Jika secure = true

    // 3. Konfigurasi Logging & Keep Alive
    client.logging(on: true);
    client.keepAlivePeriod = 20;

    // 4. Handler Callback
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = _onSubscribed;
    client.pongCallback = _pong;

    // 5. Pesan Koneksi (Optional - Last Will Message)
    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientIdentifier)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean() // Non-persistent session
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMess;

    // 6. Melakukan Koneksi
    try {
      print('MQTT: Connecting to $broker via WebSocket...');
      await client.connect();
    } on NoConnectionException catch (e) {
      print('MQTT: Client exception - $e');
      client.disconnect();
    } on SocketException catch (e) {
      print('MQTT: Socket exception - $e');
      client.disconnect();
    }
  }

  // Helper untuk Subscribe
  void subscribe(String topic) {
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  // Helper untuk Publish
  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }

  // Callbacks
  void _onConnected() {
    print('MQTT: Connected');
    // Listen to updates
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('MQTT: Topic is <${c[0].topic}>, Data: $pt');
    });
  }

  void _onDisconnected() {
    print('MQTT: Disconnected');
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to $topic');
  }

  void _pong() {
    print('MQTT: Ping response received');
  }
}
```

## 3. Poin Penting WebSocket

1.  **Port Berbeda**: WebSocket biasanya menggunakan port **8000** atau **8083**, BUKAN port standar MQTT 1883. Pastikan Anda cek dokumentasi broker Anda.
2.  **`useWebSocket = true`**: Ini properti kunci pada `mqtt_client` agar ia membungkus paket MQTT dalam frame WebSocket.
3.  **Secure vs Non-Secure**:
    *   `ws://` (Non-secure): Gunakan `client.secure = false`.
    *   `wss://` (Secure/SSL): Gunakan `client.secure = true`.
4.  **Platform Web**: Jika Anda menargetkan Flutter Web, Anda **HARUS** menggunakan `MqttBrowserClient` (bukan `MqttServerClient`). Paket `mqtt_client` menyediakan keduanya. Untuk aplikasi Cross-Platform (HP + Web), Anda mungkin perlu membuat dua file implementasi terpisah.

## 4. Cara Menggunakan di Flutter (UI)

Disarankan menggunakan Provider atau Riverpod untuk menyuntikkan service ini ke UI.

Contoh sederhana di `main.dart` atau `Controller`:
```dart
final mqttService = MqttService();
await mqttService.connect();
mqttService.subscribe('test/topic');
mqttService.publish('test/topic', 'Hello from Flutter!');
```
