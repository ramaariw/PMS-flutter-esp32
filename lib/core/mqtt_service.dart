import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  // Broker HiveMQ Cloud lu
  final String broker = 'c3a71c8ed6244283a52bcf948e798390.s1.eu.hivemq.cloud';
  final String username = 'admin';
  final String password = 'Admin1234';

  Future<MqttServerClient?> connect() async {
    // Generate ID unik biar gak bentrok kalau lu buka di dua HP
    String id =
        'pms_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    client = MqttServerClient.withPort(broker, id, 8883);
    client!.secure = true;
    client!.logging(on: false); // Matiin log biar terminal gak rame
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.autoReconnect = true;

    // Ini PENTING buat koneksi SSL/TLS di HiveMQ Cloud
    client!.onBadCertificate = (dynamic _) => true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(id)
        .authenticateAs(username, password)
        .withWillTopic('willtopic') // Opsional
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMess;

    try {
      print('MQTT: Menghubungkan ke HiveMQ...');
      await client!.connect();
      return client;
    } catch (e) {
      print('MQTT ERROR: $e');
      client?.disconnect();
      return null;
    }
  }

  void disconnect() => client?.disconnect();
}
