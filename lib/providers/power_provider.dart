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

  // --- V1.3 SYSTEM LOGS ---
  List<String> logs = [];

  // --- V1.3 CHART DATA (Watt History) ---
  List<double> wattHistory = List.filled(
    10,
    0.0,
  ); // Simpan 10 titik data terakhir

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

  // --- FUNGSI LOGGING ---
  void addLog(String message) {
    String timestamp =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    logs.insert(0, "[$timestamp] $message");
    if (logs.length > 20) logs.removeLast();
    notifyListeners();
  }

  // --- FUNGSI UPDATE CHART ---
  void _updateWattHistory(double newWatt) {
    wattHistory.removeAt(0); // Hapus data paling kiri (lama)
    wattHistory.add(newWatt); // Tambah data baru ke kanan
    notifyListeners();
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('relay1', relay1);
    await prefs.setBool('relay2', relay2);
    await prefs.setString('sch1', scheduleR1);
    await prefs.setString('sch2', scheduleR2);
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    relay1 = prefs.getBool('relay1') ?? false;
    relay2 = prefs.getBool('relay2') ?? false;
    scheduleR1 = prefs.getString('sch1') ?? "";
    scheduleR2 = prefs.getString('sch2') ?? "";
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;

    addLog("System initialized...");
    notifyListeners();
    initPms();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    addLog("Theme switched to ${_isDarkMode ? 'Dark' : 'Light'} Mode");
    _saveLocalState();
    notifyListeners();
  }

  Future<void> toggleConnection() async {
    if (isConnected) {
      addLog("Disconnecting from broker...");
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

    addLog("Connecting to HiveMQ Cloud...");
    final client = await _mqttService.connect();

    if (client != null &&
        client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      addLog("MQTT Connected successfully!");

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
          bool newState = (rawPayload == "ON");
          if (relay1 != newState) addLog("Relay 1 status: $rawPayload");
          relay1 = newState;
          _saveLocalState();
          notifyListeners();
        } else if (topic == "esp32rm/r2/stat" && canUpdateRelay) {
          bool newState = (rawPayload == "ON");
          if (relay2 != newState) addLog("Relay 2 status: $rawPayload");
          relay2 = newState;
          _saveLocalState();
          notifyListeners();
        }
      });

      client.onDisconnected = () {
        isConnected = false;
        addLog("Warning: MQTT Disconnected!");
        notifyListeners();
      };
    } else {
      isConnected = false;
      addLog("Error: Connection failed.");
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

      // Update Grafik Watt
      _updateWattHistory(watt);

      _saveLocalState();
      notifyListeners();
    } catch (e) {
      debugPrint("Parsing Error: $e");
    }
  }

  Future<void> refreshData() async {
    if (isLoading) return;
    addLog("Refreshing system connection...");
    _mqttService.disconnect();
    isConnected = false;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    await initPms();
  }

  void toggleRelay(int channel, bool value) {
    if (!isConnected || _mqttService.client == null) {
      addLog("Failed: No MQTT connection.");
      return;
    }
    HapticFeedback.mediumImpact();
    _lastRelayAction = DateTime.now();

    addLog("Cmd: Relay $channel set to ${value ? 'ON' : 'OFF'}");

    if (channel == 1) relay1 = value;
    if (channel == 2) relay2 = value;
    _saveLocalState();
    notifyListeners();
    _publish("esp32rm/r$channel/cmd", value ? "ON" : "OFF");
  }

  void sendTimerToHardware(int channel, int minutes) {
    if (!isConnected) return;
    HapticFeedback.lightImpact();
    if (minutes > 0) {
      addLog("Timer: Relay $channel set $minutes min");
    } else {
      addLog("Timer: Relay $channel cleared");
    }
    _publish("esp32rm/r$channel/timer", minutes.toString());
  }

  void sendScheduleToHardware(int channel, String time) {
    if (!isConnected) return;
    HapticFeedback.heavyImpact();

    if (time == "OFF") {
      addLog("Sch: Relay $channel cleared");
    } else {
      addLog("Sch: Relay $channel set to $time");
    }

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
