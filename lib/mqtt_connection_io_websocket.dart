library mqtt_io_ws;

import 'dart:io';
import 'dart:async';
import 'mqtt_shared.dart';

class MqttConnectionIOWebSocket extends VirtualMqttConnection{
  final String _url;
  WebSocket _ws;
  
  MqttConnectionIOWebSocket.setOptions(this._url);
  Future connect() {
    print("[WebSocket] Connecting to $_url");
    return WebSocket.connect(_url, protocols: [
      'mqtt',
      'mqttv3.1',
      'mqttv3.11'
    ]);
  }
  
  handleConnectError(e) {
    print("Error: $e");
  }
  
  privateSendMessageToBroker(MqttMessage m) {
    _ws.add(m.buf);
  }

  setConnection(cnx) {
    _ws = cnx;
  }
  
  startListening(_processData, _handleDone, _handleError) {
    _ws.listen(
      (data) => _processData(data),
      onDone: () => _handleDone(),
      onError: (e) => _handleError(e)
    );
  }
  
  close() {
    _ws.close();
  }

}
