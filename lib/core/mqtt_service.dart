import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  final String broker = 'c3a71c8ed6244283a52bcf948e798390.s1.eu.hivemq.cloud';
  final String username = 'admin';
  final String password = 'Admin1234';

  Future<MqttServerClient?> connect() async {
    String id =
        'pms_${DateTime.now().millisecondsSinceEpoch.toString().substring(10)}';
    client = MqttServerClient.withPort(broker, id, 8883);
    client!.secure = true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 20;
    client!.autoReconnect = true;
    client!.onBadCertificate = (dynamic _) => true;

    client!.connectionMessage =
        MqttConnectMessage()
            .withClientIdentifier(id)
            .authenticateAs(username, password)
            .startClean();

    try {
      await client!.connect();
      return client;
    } catch (e) {
      client?.disconnect();
      return null;
    }
  }

  void disconnect() => client?.disconnect();
}
