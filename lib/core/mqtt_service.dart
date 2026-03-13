import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  final String broker = 'c3a71c8ed6244283a52bcf948e798390.s1.eu.hivemq.cloud';
  final String username = 'admin';
  final String password = 'Admin1234';

  Future<MqttServerClient?> connect() async {
    // ID acak biar gak bentrok (kunci anti-blokir)
    String id =
        'pms_${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';

    client = MqttServerClient.withPort(broker, id, 8883);
    client!.secure = true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.onBadCertificate = (dynamic _) => true;
    client!.logging(on: true);

    // TAMBAH INI: Biar kalo sinyal ilang dia nyambung sendiri gak perlu pencet lagi
    client!.autoReconnect = true;

    final connMessage =
        MqttConnectMessage()
            .withClientIdentifier(id)
            .authenticateAs(username, password)
            .startClean();

    client!.connectionMessage = connMessage;

    try {
      print('MQTT: Mencoba koneksi dengan ID: $id');
      await client!.connect();
      return client;
    } catch (e) {
      print('MQTT Error: $e');
      client?.disconnect();
      return null;
    }
  }

  // TAMBAH INI: Fungsi buat tombol DISCONNECT
  void disconnect() {
    print("MQTT: Memutuskan koneksi manual...");
    client?.disconnect();
  }
}
