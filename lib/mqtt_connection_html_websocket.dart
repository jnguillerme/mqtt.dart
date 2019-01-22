library mqtt_html_ws;

import 'dart:html';
import 'dart:async';
import 'mqtt_shared.dart';
import 'dart:typed_data';

class MqttConnectionHtmlWebSocket extends VirtualMqttConnection{
  final String _url;
  final String _protocol;
  WebSocket _ws;

  MqttConnectionHtmlWebSocket.setOptions(this._url, this._protocol);

  Future connect() {
    print("[HTML WebSocket] Connecting to $_url");

    Completer connected = new Completer();
    if (_protocol != null) {
      _ws = new WebSocket(_url, _protocol);
    } else {
      _ws = new WebSocket(_url);
    }
    _ws.binaryType = "arraybuffer";
    _ws.onOpen.listen((e) {
      connected.complete(_ws);
    });

    return connected.future;
  }

  handleConnectError(e) {
    print("Error: $e");
  }

  privateSendMessageToBroker(MqttMessage m) {
    print("[HTML WebSocket] SendMessage ${m.buf}");
    _ws.send(new Uint8List.fromList(m.buf));
  }

  setConnection(cnx) {
    //_ws = cnx;
  }

  startListening(_processData, _handleDone, _handleError) {
    _ws.onClose.listen( (e) => _handleDone());
    _ws.onMessage.listen( (MessageEvent e) => _processData(e.data) );
    _ws.onError.listen( (e) => _handleError(e) );
  }

  close() {
    _ws.close();
  }

}
