import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../core/mqtt_service.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class PowerProvider with ChangeNotifier {
  final MqttService _mqttService = MqttService();

  double acVolt = 0.0, ampere = 0.0, watt = 0.0, kwh = 0.0, dcVolt = 0.0;
  int batStatus = 0;
  bool isConnected = false;
  bool isLoading = false;
  bool relay1 = false;
  bool relay2 = false;
  String uptime = "00:00:00";
  int remainingSecondsR1 = 0;
  int remainingSecondsR2 = 0;
  String scheduleR1 = "";
  String scheduleR2 = "";

  // PENJAGA BIAR GAK JOGET:
  DateTime? _lastRelayAction;
  Timer? _relayTimer;
  int remainingSeconds = 0;

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
    final client = await _mqttService.connect();

    if (client != null &&
        client.connectionStatus!.state == MqttConnectionState.connected) {
      isConnected = true;
      notifyListeners();

      client.subscribe("esp32rm/sensor", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r1/stat", MqttQos.atLeastOnce);
      client.subscribe("esp32rm/r2/stat", MqttQos.atLeastOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final String topic = c[0].topic;
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String rawPayload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        // LOGIKA PENJAGA: Cek apakah aksi terakhir sudah lebih dari 2 detik
        bool canUpdateRelay =
            _lastRelayAction == null ||
            DateTime.now().difference(_lastRelayAction!).inSeconds > 2;

        if (topic == "esp32rm/sensor") {
          _updateData(rawPayload);
        } else if (topic == "esp32rm/r1/stat" && canUpdateRelay) {
          relay1 = (rawPayload == "ON");
          notifyListeners();
        } else if (topic == "esp32rm/r2/stat" && canUpdateRelay) {
          relay2 = (rawPayload == "ON");
          notifyListeners();
        }
      });

      client.onDisconnected = () {
        isConnected = false;
        notifyListeners();
      };
    } else {
      isConnected = false;
      notifyListeners();
    }
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

      // SINKRONISASI TIMER DARI HARDWARE (ESP32)
      remainingSecondsR1 = (data['t1_rem'] ?? 0).toInt();
      remainingSecondsR2 = (data['t2_rem'] ?? 0).toInt();
      
      // SINKRONISASI JADWAL
      scheduleR1 = data['sch_1']?.toString() ?? "";
      scheduleR2 = data['sch_2']?.toString() ?? "";

      notifyListeners();
    } catch (e) {
      debugPrint("Error Parsing: $e");
    }
  }

  // Fungsi Kirim Timer ke ESP32 (Lewat MQTT)
  void sendTimerToHardware(int channel, int minutes) {
    if (!isConnected) return;
    HapticFeedback.lightImpact();
    
    // Kirim payload angka menit ke topik timer
    String topic = "esp32rm/r$channel/timer";
    _publishPayload(topic, minutes.toString());
  }

  // Fungsi Kirim Jadwal (Format "HH:MM")
  void sendScheduleToHardware(int channel, String time) {
    if (!isConnected) return;
    String topic = "esp32rm/r$channel/schedule";
    _publishPayload(topic, time);
  }

  // Helper formatting sisa waktu
  String formatRemainingTime(int seconds) {
    if (seconds <= 0) return "00:00";
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  // Fungsi Publish (Biar kodingan lu gak berulang)
  void _publishPayload(String topic, String payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);
    _mqttService.client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }
}

  Future<void> refreshData() async {
    isLoading = true;
    notifyListeners();

    if (isConnected) {
      _mqttService.disconnect();
      isConnected = false;
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 500));
      await initPms();
    } else {
      await initPms();
    }

    isLoading = false;
    notifyListeners();
  }

  void toggleRelay(int channel, bool value) {
    if (!isConnected || _mqttService.client == null) return;

    HapticFeedback.mediumImpact();
    _lastRelayAction = DateTime.now();

    if (channel == 1) relay1 = value;
    if (channel == 2) relay2 = value;
    notifyListeners();

    String topic = "esp32rm/r$channel/cmd";
    String payload = value ? "ON" : "OFF";
    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    _mqttService.client!.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
      retain: true,
    );
  }

  void setRelayTimer(int minutes, int channel) {
    HapticFeedback.mediumImpact();
    _relayTimer?.cancel();
    remainingSeconds = minutes * 60;
    notifyListeners();

    _relayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        remainingSeconds--;
        notifyListeners();
      } else {
        toggleRelay(channel, false);
        _relayTimer?.cancel();
        notifyListeners();
      }
    });
  }

  String get formattedTimer {
    int m = remainingSeconds ~/ 60;
    int s = remainingSeconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }
}
