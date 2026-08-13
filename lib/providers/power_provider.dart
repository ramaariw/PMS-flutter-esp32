import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <--- AMAN: Hive Masuk
import '../core/mqtt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PowerProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();

  // --- V1.3 THEME STATE ---
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  // --- V1.3 SYSTEM LOGS ---
  List<String> logs = [];

  // --- GROWABLE LIST (ANTI-CRASH) ---
  List<double> wattHistory = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  // --- DATA SENSOR AC (PZEM-004T) ---
  double acVolt = 0.0;
  double ampere = 0.0;
  double watt = 0.0;
  double kwh = 0.0;

  // --- UPGRADE DATA SENSOR DC V2.0 (INA219) ---
  double _voltageDC = 0.0;
  double _currentDC = 0.0;
  double _powerDC = 0.0;
  double _batteryPercent = 0.0;

  // Getter data DC murni biar bisa dibaca di DcMonitorSection
  double get dcVolt => _voltageDC; // Alias biar nyambung ke screen lama
  double get voltageDC => _voltageDC;
  double get currentDC => _currentDC;
  double get powerDC => _powerDC;
  double get batteryPercent => _batteryPercent;
  int get batStatus =>
      _batteryPercent.toInt(); // Konversi int buat kecocokan UI lama

  String uptime = "00:00:00";
  String timeString = "--:--:--";

  // --- STATE TIMELINE GRAPH FILTER ---
  String _selectedTimeFilter = "5 Min";
  String get selectedTimeFilter => _selectedTimeFilter;

  // --- V1.3 CUSTOM TARIF STATE ---
  double _customTarif = 1444.70; // Nilai default default PLN R-1 1300VA
  double get customTarif => _customTarif;

  // --- KUNCI UTAMA HIVE: Link-kan langsung ke Box Database HP ---
  final _wattBox = Hive.box('pms_watt_db');

  List<Map<String, dynamic>> get rawWattLogs {
    return _wattBox.values.map((item) {
      return Map<String, dynamic>.from(item as Map);
    }).toList();
  }

  // Status Koneksi & UI
  bool isConnected = false;
  bool isLoading = false;
  bool relay1 = false;
  bool relay2 = false;

  int remainingSecondsR1 = 0;
  int remainingSecondsR2 = 0;
  String scheduleR1 = "";
  String scheduleR2 = "";

  DateTime? _lastRelayAction;
  StreamSubscription? _mqttSubscription;

  void addLog(String message) {
    String timestamp =
        "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    logs.insert(0, "[$timestamp] $message");
    if (logs.length > 20) logs.removeLast();
    notifyListeners();
  }

  Future<void> _saveLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('relay1', relay1);
    await prefs.setBool('relay2', relay2);
    await prefs.setString('sch1', scheduleR1);
    await prefs.setString('sch2', scheduleR2);
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setDouble('customTarif', _customTarif);
  }

  Future<void> loadLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    relay1 = prefs.getBool('relay1') ?? false;
    relay2 = prefs.getBool('relay2') ?? false;
    scheduleR1 = prefs.getString('sch1') ?? "";
    scheduleR2 = prefs.getString('sch2') ?? "";
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    _customTarif = prefs.getDouble('customTarif') ?? 1444.70;

    isConnected = false;
    isLoading = false;

    addLog("System initialized (Ready to Connect)...");
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    addLog("Theme switched to ${_isDarkMode ? 'Dark' : 'Light'} Mode");
    _saveLocalState();
    notifyListeners();
  }

  Future<void> toggleConnection() async {
    if (isConnected) {
      addLog("Manual request: Disconnecting...");
      await disconnectAndClean();
    } else {
      await initPms();
    }
  }

  Future<void> disconnectAndClean() async {
    isLoading = true;
    notifyListeners();
    try {
      await _mqttSubscription?.cancel();
      _mqttSubscription = null;
      _mqttService.disconnect();
    } catch (e) {
      debugPrint("Disposing error: $e");
    }
    isConnected = false;
    isLoading = false;
    addLog("MQTT Disconnected & Session Cleared.");
    notifyListeners();
  }

  Future<void> initPms() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    addLog("Connecting to HiveMQ Cloud...");
    final activeClient = await _mqttService.connect();

    if (activeClient != null &&
        activeClient.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      addLog("MQTT Connected successfully!");

      _mqttService.subscribe("esp32rm/sensor");
      _mqttService.subscribe("esp32rm/r1/stat");
      _mqttService.subscribe("esp32rm/r2/stat");

      await _mqttSubscription?.cancel();

      final stream = _mqttService.getMessagesStream();
      if (stream != null) {
        _mqttSubscription = stream.listen(
          (List<MqttReceivedMessage<MqttMessage>> c) {
            final String topic = c[0].topic;
            final MqttPublishMessage recMess =
                c[0].payload as MqttPublishMessage;
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
          },
          onError: (err) {
            addLog("Stream Error: $err");
          },
        );
      }

      activeClient.onDisconnected = () {
        isConnected = false;
        addLog("Warning: MQTT Disconnected!");
        _mqttSubscription?.cancel();
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

      // --- PARSING DATA AC (PZEM) ---
      acVolt = double.tryParse(data['v_ac']?.toString() ?? '0') ?? 0.0;
      ampere = double.tryParse(data['a_ac']?.toString() ?? '0') ?? 0.0;
      watt = double.tryParse(data['w_ac']?.toString() ?? '0') ?? 0.0;
      kwh = double.tryParse(data['e_ac']?.toString() ?? '0') ?? 0.0;

      // --- PARSING DATA DC SAKTI V2.0 (INA219) ---
      _voltageDC = double.tryParse(data['v_dc']?.toString() ?? '0') ?? 0.0;
      _currentDC =
          double.tryParse(data['a_dc']?.toString() ?? '0') ??
          0.0; // Ambil Amps DC murni
      _powerDC =
          double.tryParse(data['w_dc']?.toString() ?? '0') ??
          0.0; // Ambil Watt DC murni
      _batteryPercent = double.tryParse(data['bat']?.toString() ?? '0') ?? 0.0;

      uptime = data['uptime']?.toString() ?? "00:00:00";
      timeString = data['time']?.toString() ?? "--:--:--";

      if (data.containsKey('t1_rem')) {
        remainingSecondsR1 = int.tryParse(data['t1_rem'].toString()) ?? 0;
      }
      if (data.containsKey('t2_rem')) {
        remainingSecondsR2 = int.tryParse(data['t2_rem'].toString()) ?? 0;
      }
      if (data.containsKey('sch_1')) {
        scheduleR1 = data['sch_1']?.toString() ?? "";
      }
      if (data.containsKey('sch_2')) {
        scheduleR2 = data['sch_2']?.toString() ?? "";
      }

      // --- KUNCI UTAMA HIVE: Tulis Langsung ke Storage HP ---
      DateTime timestampNow = DateTime.now();
      _wattBox.add({
        "time":
            timestampNow
                .toIso8601String(), // Simpan format ISO String biar aman
        "watt": watt,
      });

      // --- LOGIC AUTO-CLEANSING 24 JAM (SABUK PENGAMAN MEMORI) ---
      DateTime cutoff24HoursAgo = timestampNow.subtract(
        const Duration(hours: 24),
      );
      List<dynamic> keysToDelete = [];
      for (var i = 0; i < _wattBox.length; i++) {
        var item = _wattBox.getAt(i);
        if (item != null) {
          DateTime itemTime = DateTime.parse(item['time']);
          if (itemTime.isBefore(cutoff24HoursAgo)) {
            keysToDelete.add(_wattBox.keyAt(i));
          }
        }
      }
      if (keysToDelete.isNotEmpty) {
        _wattBox.deleteAll(keysToDelete);
      }

      // --- JALANKAN REFRESH SKALA GRAFIK SESUAI FILTER YANG SEDANG DIPILIH ---
      generateFilteredHistory(_selectedTimeFilter);

      notifyListeners();
    } catch (e) {
      debugPrint("Parsing Error: $e");
    }
  }

  // --- SETTER SYNC FILTER DARI TOMBOL UI KE PROVIDER ---
  void setSelectedTimeFilter(String filter) {
    _selectedTimeFilter = filter;
    generateFilteredHistory(filter);
  }

  void generateFilteredHistory(String filter) {
    DateTime now = DateTime.now();
    DateTime cutoff;

    switch (filter) {
      case "5 Min":
        cutoff = now.subtract(const Duration(minutes: 5));
        break;
      case "15 Min":
        cutoff = now.subtract(const Duration(minutes: 15));
        break;
      case "30 Min":
        cutoff = now.subtract(const Duration(minutes: 30));
        break;
      case "1 Hour":
        cutoff = now.subtract(const Duration(hours: 1));
        break;
      case "6 Hour":
        cutoff = now.subtract(const Duration(hours: 6));
        break;
      case "12 Hour":
        cutoff = now.subtract(const Duration(hours: 12));
        break;
      case "24 Hour":
        cutoff = now.subtract(const Duration(hours: 24));
        break;
      default:
        cutoff = now.subtract(const Duration(minutes: 5));
    }

    // --- PEMBETULAN PARSING DATE UNTUK STRUKTUR HIVE ---
    List<double> filteredValues =
        rawWattLogs
            .where((log) {
              DateTime logTime = DateTime.parse(log['time'] as String);
              return logTime.isAfter(cutoff);
            })
            .map((log) => (log['watt'] as double))
            .toList();

    if (filteredValues.length < 10) {
      wattHistory = List.from(filteredValues);
      while (wattHistory.length < 10) {
        wattHistory.insert(0, 0.0);
      }
    } else {
      List<double> sampledPoints = [];
      int chunkSize = filteredValues.length ~/ 10;
      for (int i = 0; i < 10; i++) {
        int start = i * chunkSize;
        int end = (i == 9) ? filteredValues.length : start + chunkSize;
        double chunkAverage =
            filteredValues.sublist(start, end).reduce((a, b) => a + b) /
            (end - start);
        sampledPoints.add(chunkAverage);
      }
      wattHistory = sampledPoints;
    }

    notifyListeners(); // <--- SAKTI: Paksa grafik UI rendering ulang setelah difilter!
  }

  Future<void> refreshData() async {
    if (isLoading) return;
    addLog("Refreshing system connection...");
    await disconnectAndClean();
    await Future.delayed(const Duration(milliseconds: 500));
    await initPms();
  }

  void toggleRelay(int channel, bool value) {
    if (!isConnected) {
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
    final activeClient = _mqttService.client;
    if (activeClient == null ||
        activeClient.connectionStatus!.state != MqttConnectionState.connected) {
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    activeClient.publishMessage(
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

  // FUNGSI UPDATE TARIF DARI USER INPUT
  void updateTarif(double newTarif) {
    _customTarif = newTarif;
    _saveLocalState();
    addLog("Tarif PLN updated to: Rp ${newTarif.toStringAsFixed(2)}/kWh");
    notifyListeners();
  }
}
