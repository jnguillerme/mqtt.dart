import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
/**s
 * class MqttWsBridgeOptions
 * Handle options available for the mqtt_ws programm
 * 
 * --mqttHost     : mqtt broker host. Default is 127.0.0.1
 * --mqttPort     : mqtt broker port. Default is 1883
 * -listeningPort : bridge listening port. Default is 8080 
 */

class MqttWsBridgeOptions {
  var options = ['mqttHost', 'mqttPort', 'listeningPort'];

  num listeningPort = 8080;
  String mqttHost = "127.0.0.1";
  num mqttPort = 1883;
  
  ArgParser argParser() {
    var parser = new ArgParser();
    
    parser.addOption('mqttHost', 
                      abbr:'h', 
                      defaultsTo: '127.0.0.1', 
                      help: 'Mqtt broker host to connect to. Default is 127.0.0.1',
                      callback: (host) => mqttHost = host);
    
    parser.addOption('mqttPort', 
                      abbr:'p', 
                      defaultsTo: '1883', 
                      help: 'Mqtt broker port to connect to. Default is 1883',
                      callback: (port) => mqttPort = int.parse(port));
    
    parser.addOption('listeningPort', 
                      abbr:'P', 
                      defaultsTo: '127.0.0.1', 
                      help: 'Bridge listening port. Default is 8080',
                      callback: (port) => listeningPort = int.parse(port));
    
    
    return parser;
  }
}

/**
 * class SocketWebSocketMapper
 * Route all message received on the websocket to the mqtt broker
 * and all messages received from the broker to the websocket
 */

class SocketWebSocketMapper {
  Socket s;
  WebSocket ws;
  
  SocketWebSocketMapper(this.s, this.ws);

  void processDataOnSocket(data) {
    print("[SOCKET] ${data}");
    ws.add(data);
  }
  void handleDoneOnSocket() {
    print("Done on Socket");
    ws.close();
  }
  
  void handleErrorOnSocket(e) {
    print("Error on socket: $e");  
    test: (e) => e is SocketException;
  }  
  void processDataOnWebSocket(data) {
    print("[WEBSOCKET] ${data}");    
    s.add(data);
  }
  void handleDoneOnWebSocket() {
    print("Done on webSocket");
    ws.close();
    Future.wait([s.close()]);
  }
  void handleErrorOnWebSocket(e) {
    print("Error on webSocket: $e"); 
    test: (e) => e is SocketException;
  }

}
/**
 * class MqttWebSocketBridge
 */
class MqttWebSocketBridge {
   
  String _mqttHost;
  num _mqttPort;
  
  MqttWebSocketBridge(this._mqttHost, this._mqttPort);
  
  onConnection(WebSocket ws) {
    // connect to mqtt broker
    print("New webSocket connection. Connecting to mqtt broker ${_mqttHost}:${_mqttPort}");
    Socket.connect(_mqttHost, _mqttPort).then( (s) {
      print("Connected");
      SocketWebSocketMapper m = new SocketWebSocketMapper(s, ws);
      s.listen(   (data) => m.processDataOnSocket(data),
                    onDone: () => m.handleDoneOnSocket(),
                    onError: (e) => m.handleErrorOnSocket(e)
        );
      ws.listen(  (data) => m.processDataOnWebSocket(data),
                  onDone: () => m.handleDoneOnWebSocket(),
                  onError: (e) => m.handleErrorOnWebSocket(e)
        );
    });  
  }
}

/**
 * main
 */
void main() {
  print('starting...');
  
  MqttWsBridgeOptions bridgeOptions = new MqttWsBridgeOptions();
  bridgeOptions.argParser().parse(bridgeOptions.options);
  
  print('Bridgeoptions host : $bridgeOptions.mqttHost'); 
  HttpServer.bind('127.0.0.1', bridgeOptions.listeningPort)
    .then((HttpServer server) {
      print('listening for connections on ${bridgeOptions.listeningPort}');
      
      var wsBridge = new MqttWebSocketBridge(bridgeOptions.mqttHost, bridgeOptions.mqttPort);
      var sc = new StreamController();
      sc.stream
        .transform(new WebSocketTransformer())
        .listen(wsBridge.onConnection);
      
      server.listen((HttpRequest request) {
        if (request.uri.path == '/') {
          sc.add(request);
        }
      });
    },
    onError: (error) => print("Error starting HTTP server: $error"));

}
