import 'dart:io'; // WAJIB ADA BUAT SECURITYCONTEXT
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/material.dart';

class MqttService {
  MqttServerClient? client;
  // Broker HiveMQ Cloud lu
  final String broker = '552436bf82c24d77a9f19b1587fa5907.s1.eu.hivemq.cloud';
  final String username = 'pmsv2.0';
  final String password = 'PowermonitoringsystemV2.0';

  Future<MqttServerClient?> connect() async {
    // Generate ID unik biar gak bentrok kalau lu buka di dua HP
    String id =
        'pms_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    client = MqttServerClient.withPort(broker, id, 8883);

    // --- UPDATE SAKTI: AMANKAN KONEKSI SECURE DARI TIMEOUT & ABORT 103 ---
    client!.secure = true;
    client!.securityContext =
        SecurityContext.defaultContext; // Pake certificate legal bawaan OS
    client!.setProtocolV311();

    // Longgarin nafas ping biar gak gampang ditendang server Eropa kalau jaringan lag
    client!.keepAlivePeriod = 60;
    client!.autoReconnect = true;
    client!.logging(on: false); // Matiin log biar terminal gak rame

    // Sebagai backup tambahan penjinak handshake
    client!.onBadCertificate = (dynamic _) => true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(id)
        .authenticateAs(username, password)
        .withWillTopic('willtopic') // Opsional
        .withWillMessage('Disconnected abnormally')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMess;

    try {
      debugPrint('MQTT: Menghubungkan & Secure TLS Handshake ke HiveMQ...');
      await client!.connect();
      return client;
    } catch (e) {
      debugPrint('MQTT ERROR SOKET: $e');
      client?.disconnect();
      return null;
    }
  }

  // --- FUNGSI SUBSCRIBE SINKRON ---
  void subscribe(String topic) {
    if (client != null &&
        client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.subscribe(topic, MqttQos.atLeastOnce);
      debugPrint('MQTT: Sukses Subscribe ke Topik -> $topic');
    } else {
      debugPrint('MQTT ERROR: Gagal subscribe, client belum konek.');
    }
  }

  // --- GETTER STREAM SECURE NYAMBUNG KE PROVIDER ---
  Stream<List<MqttReceivedMessage<MqttMessage>>>? getMessagesStream() {
    if (client == null) return null;
    return client!.updates;
  }

  void disconnect() => client?.disconnect();
}
