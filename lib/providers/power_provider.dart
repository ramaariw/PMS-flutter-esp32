import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../core/mqtt_service.dart';

class PowerProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();

  double acVolt = 0.0, ampere = 0.0, watt = 0.0, kwh = 0.0, dcVolt = 0.0;
  int batStatus = 0;
  bool isConnected = false;
  bool relay1 = false;
  bool relay2 = false;
  String uptime = "00:00:00";
  int uptimeSeconds = 0;

  // FUNGSI TOGGLE: Panggil ini di tombol Dashboard
  Future<void> toggleConnection() async {
    if (isConnected) {
      // Kalau lagi ONLINE, kita matikan
      _mqttService.disconnect();
      isConnected = false;
      notifyListeners();
    } else {
      // Kalau lagi OFFLINE, kita nyalakan
      await initPms();
    }
  }

  Future<void> initPms() async {
    final client = await _mqttService.connect();

    if (client != null &&
        client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      notifyListeners();

      // 1. Subscribe ulang (Penting!)
      client.subscribe("esp32rm/sensor", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r1/stat", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r2/stat", MqttQos.atLeastOnce);

      // 2. Bersihkan listener lama & dengerin berbagai topik
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final String topic = c[0].topic; // Ambil nama topiknya dulu
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String rawPayload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        // Filter berdasarkan Topik
        if (topic == "esp32rm/sensor") {
          print("BINGGO! Data Sensor: $rawPayload");
          _updateData(rawPayload);
        } else if (topic == "esp32rm/r1/stat") {
          print("STATUS RELAY 1: $rawPayload");
          relay1 = (rawPayload == "ON"); // Update switch di dashboard
          notifyListeners();
        } else if (topic == "esp32rm/r2/stat") {
          print("STATUS RELAY 2: $rawPayload");
          relay2 = (rawPayload == "ON"); // Update switch di dashboard
          notifyListeners();
        }
      });
      client.onDisconnected = () {
        isConnected = false;
        notifyListeners();
        print("MQTT: Yah, Putus Lagi...");
      };
    } else {
      print("MQTT: Gagal konek, bro!");
      isConnected = false;
      notifyListeners();
    }
  }

  void _updateData(String rawData) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawData);

      print("ISI JSON: $data");

      // Data numerik tetap aman pake toDouble/toInt
      acVolt = (data['v_ac'] ?? 0.0).toDouble();
      ampere = (data['a_ac'] ?? 0.0).toDouble();
      watt = (data['w_ac'] ?? 0.0).toDouble();
      kwh = (data['e_ac'] ?? 0.0).toDouble();
      dcVolt = (data['v_dc'] ?? 0.0).toDouble();
      batStatus = (data['bat'] ?? 0).toInt();

      // BAGIAN FIX UPTIME:
      // Karena dari ESP udah berupa String "1d 01:25:51",
      // Langsung masukin aja ke variabel uptime tanpa convert lagi.
      uptime = data['uptime']?.toString() ?? "00:00:00";

      print("UPTIME BERHASIL: $uptime");
      notifyListeners();
    } catch (e) {
      // Sekarang error casting tadi harusnya ilang
      print("Parsing JSON Error: $e");
    }
  }

  // Fungsi pembantu buat format waktu biar cakep
  String _formatUptime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    // Format jadi 00:00:00
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  //buat refresh cuy

  Future<void> refreshData() async {
    if (isConnected) {
      print("MQTT: Refreshing connection...");
      // Putus sebentar
      _mqttService.disconnect();
      isConnected = false;
      notifyListeners();

      // Tunggu sedetik biar server HiveMQ napas
      await Future.delayed(Duration(milliseconds: 500));

      // Konek lagi
      await initPms();
      print("MQTT: Data refreshed!");
    } else {
      // Kalau emang lagi offline, ya tinggal konekin aja
      await initPms();
    }
  }

  void toggleRelay(int channel, bool value) {
    if (!isConnected || _mqttService.client == null) {
      print("MQTT: Belum konek!");
      return;
    }

    // 1. Update UI Lokal
    if (channel == 1) relay1 = value;
    if (channel == 2) relay2 = value;
    notifyListeners();

    // 2. Sesuaikan Topik dengan main.cpp ESP32
    // ESP32 lu minta: "esp32rm/r1/cmd" atau "esp32rm/r2/cmd"
    String topic = "esp32rm/r$channel/cmd";

    // Payloadnya: "ON" atau "OFF"
    String payload = value ? "ON" : "OFF";

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _mqttService.client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true, // Bagus biar pas ESP nyala langsung baca status terakhir
    );

    print("Sent to ESP32: $topic -> $payload");
  }
}
