import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../core/mqtt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PowerProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();

  // --- V1.3 THEME STATE ---
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  // Data Sensor
  double acVolt = 0.0, ampere = 0.0, watt = 0.0, kwh = 0.0, dcVolt = 0.0;
  int batStatus = 0;
  String uptime = "00:00:00";

  // Status Koneksi & UI
  bool isConnected = false;
  bool isLoading = false;
  bool relay1 = false;
  bool relay2 = false;

  // Data Timer & Schedule
  int remainingSecondsR1 = 0;
  int remainingSecondsR2 = 0;
  String scheduleR1 = "";
  String scheduleR2 = "";

  DateTime? _lastRelayAction;

  // UPDATE V1.3: Simpan tema ke HP
  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('relay1', relay1);
    await prefs.setBool('relay2', relay2);
    await prefs.setString('sch1', scheduleR1);
    await prefs.setString('sch2', scheduleR2);
    await prefs.setBool('isDarkMode', _isDarkMode); // Simpan status tema
  }

  // UPDATE V1.3: Load tema pas startup
  Future<void> loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    relay1 = prefs.getBool('relay1') ?? false;
    relay2 = prefs.getBool('relay2') ?? false;
    scheduleR1 = prefs.getString('sch1') ?? "";
    scheduleR2 = prefs.getString('sch2') ?? "";
    _isDarkMode = prefs.getBool('isDarkMode') ?? true; // Default Dark

    notifyListeners();
    initPms();
  }

  // FUNGSI BARU V1.3
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveLocalState();
    notifyListeners();
  }

  // --- LOGIC HARDWARE & MQTT (TETEP V1.2 - GAK BERUBAH) ---
  Future<void> toggleConnection() async {
    if (isConnected) {
      _mqttService.disconnect();
      isConnected = false;
      notifyListeners();
    } else {
      await initPms();
    }
  }

  Future<void> initPms() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    final client = await _mqttService.connect();

    if (client != null &&
        client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      client.subscribe("esp32rm/sensor", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r1/stat", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r2/stat", MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final String topic = c[0].topic;
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String rawPayload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        bool canUpdateRelay =
            _lastRelayAction == null ||
            DateTime.now().difference(_lastRelayAction!).inSeconds > 2;

        if (topic == "esp32rm/sensor") {
          _updateData(rawPayload);
        } else if (topic == "esp32rm/r1/stat" && canUpdateRelay) {
          relay1 = (rawPayload == "ON");
          _saveLocalState();
          notifyListeners();
        } else if (topic == "esp32rm/r2/stat" && canUpdateRelay) {
          relay2 = (rawPayload == "ON");
          _saveLocalState();
          notifyListeners();
        }
      });

      client.onDisconnected = () {
        isConnected = false;
        notifyListeners();
      };
    } else {
      isConnected = false;
    }
    isLoading = false;
    notifyListeners();
  }

  void _updateData(String rawData) {
    try {
      final Map<String, dynamic> data = jsonDecode(rawData);
      acVolt = (data['v_ac'] ?? 0.0).toDouble();
      ampere = (data['a_ac'] ?? 0.0).toDouble();
      watt = (data['w_ac'] ?? 0.0).toDouble();
      kwh = (data['e_ac'] ?? 0.0).toDouble();
      dcVolt = (data['v_dc'] ?? 0.0).toDouble();
      batStatus = (data['bat'] ?? 0).toInt();
      uptime = data['uptime']?.toString() ?? "00:00:00";
      remainingSecondsR1 = (data['t1_rem'] ?? 0).toInt();
      remainingSecondsR2 = (data['t2_rem'] ?? 0).toInt();
      scheduleR1 = data['sch_1']?.toString() ?? "";
      scheduleR2 = data['sch_2']?.toString() ?? "";

      _saveLocalState();
      notifyListeners();
    } catch (e) {
      debugPrint("Parsing Error: $e");
    }
  }

  Future<void> refreshData() async {
    if (isLoading) return;
    _mqttService.disconnect();
    isConnected = false;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    await initPms();
  }

  void toggleRelay(int channel, bool value) {
    if (!isConnected || _mqttService.client == null) return;
    HapticFeedback.mediumImpact();
    _lastRelayAction = DateTime.now();
    if (channel == 1) relay1 = value;
    if (channel == 2) relay2 = value;
    _saveLocalState();
    notifyListeners();
    _publish("esp32rm/r$channel/cmd", value ? "ON" : "OFF");
  }

  void sendTimerToHardware(int channel, int minutes) {
    if (!isConnected) return;
    HapticFeedback.lightImpact();
    _publish("esp32rm/r$channel/timer", minutes.toString());
  }

  void sendScheduleToHardware(int channel, String time) {
    if (!isConnected) return;
    HapticFeedback.heavyImpact();
    _publish("esp32rm/r$channel/schedule", time);
    if (channel == 1) scheduleR1 = time;
    if (channel == 2) scheduleR2 = time;
    _saveLocalState();
    notifyListeners();
  }

  void _publish(String topic, String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _mqttService.client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  String formatRemainingTime(int seconds) {
    if (seconds <= 0) return "00:00";
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
