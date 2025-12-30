import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io' show Platform;

// Abstract factory to create the right client based on platform
MqttClient updateAndGetClient(
    String server, String clientIdentifier, int port) {
  if (kIsWeb) {
    // For web, we must use the browser client
    final client = MqttBrowserClient('wss://$server', clientIdentifier);
    client.port = port;
    return client;
  } else {
    // For mobile/desktop, we use the server client but configured for websocket if needed
    // However, HiveMQ public broker port 8000 is usually WebSocket.
    // The mqtt_client package separates Browser and Server clients.
    // For simplicity and "ws" usage on non-web, we might need MqttServerClient with useWebSocket = true.
    final client = MqttServerClient(server, clientIdentifier);
    client.useWebSocket = true;
    client.port = port;
    return client;
  }
}

class MqttService {
  late MqttClient client;

  final String _server = 'ws://broker.hivemq.com/mqtt';
  final int _port = 8000; // WebSocket port for HiveMQ public broker
  final String _topic = 'TERIMA_DATA';
  final String _clientId =
      'flutter_mqtt_client_${DateTime.now().millisecondsSinceEpoch}';

  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messages => _messageController.stream;

  Future<void> connect() async {
    client = updateAndGetClient(_server, _clientId, _port);

    // Set logging
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    // Callbacks
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
    client.onSubscribed = _onSubscribed;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .withWillTopic('willtopic')
        .withWillMessage('My Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      print('MQTT: Connecting to $_server:$_port...');
      await client.connect();
    } on Exception catch (e) {
      print('MQTT: Connection failed - $e');
      client.disconnect();
    }
  }

  void _onConnected() {
    print('MQTT: Connected');
    isConnected.value = true;
    _subscribe();
  }

  void _onDisconnected() {
    print('MQTT: Disconnected');
    isConnected.value = false;
  }

  void _onSubscribed(String topic) {
    print('MQTT: Subscribed to $topic');
  }

  void _subscribe() {
    client.subscribe(_topic, MqttQos.atLeastOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print(
          'MQTT: Message received: topic is <${c[0].topic}>, payload is <-- $pt -->');
      _messageController.add(pt);
    });
  }

  void publish(String message) {
    if (client.connectionStatus!.state != MqttConnectionState.connected) {
      print('MQTT: Cannot publish, not connected');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(_topic, MqttQos.exactlyOnce, builder.payload!);
    print('MQTT: Published "$message" to $_topic');
  }

  void disconnect() {
    client.disconnect();
  }
}
