import 'dart:io';
import 'package:mqtt/mqtt_shared.dart';
import 'package:mqtt/mqtt_connection_io_socket.dart';
import 'package:mqtt/mqtt_connection_io_websocket.dart';

/**
 * mqtt_pub
 * Sample file showing how to use the mqtt lib
 * 
 * options
 *  -?, --help display help message
 *  -d enable debug message
 *  -h host to connect to. Default is 127.0.0.1
 *  -p port to connect to. Default is 1883
 *  --url broker url for websocket connection
 *  -c clienID
 *  -i messageID
 *  -t topic
 *  -m message payload
 *  -q quality of service. Default is 0
 *  -r message should be retained
 *  -u provide a username
 *  -P provide a password
 *  --will-payload payload for the client will
 *  --will-qos  quality of service for the client will
 *  --will-retain if provided, make the client will retain
 *  --will-topic  the topic on which to publish the client will
 *  
 *  [ADD CERTICATE / ENCRYPTION support]
 *  
 */

class MqttPubOptions {
  static Map<String, String> optionList = {
                        '-?': 'display help message',
                        '-d': 'enable debug message',
                        '-h': 'host to connect to. Default is 127.0.0.1',
                        '-p': 'port to connect to. Default is 1883',
                        '--url' : 'broker url for websocket connection',
                        '-c': 'client ID',
                        '-i': 'message ID',
                        '-t': 'topic',
                        '-m': 'message payload',
                        '-q': 'quality of service. Default is 0',
                        '-r': 'message should be retained',
                        '-u': 'provide a username',
                        '-P': 'provide a password',
                        '--will-payload': 'payload for the client will',
                        '--will-qos': 'quality of service for the client will',
                        '--will-retain': 'if provided, make the client will retain',
                        '--will-topic': 'the topic on which to publish the client will'};
  
  bool debugMessage = false;
  String host = '127.0.0.1';
  num port= 1883;
  String url = null;
  String clientID = "mqtt_dart_pub";
  num messageID = 0;
  String topic;
  String payload;
  int QoS = QOS_0;
  bool retain = false;
  String user = "";
  String password = "";
  
  String willTopic = null;
  String willPayload = null;
  int willQoS = QOS_0;
  bool willRetain = false;
  
   void displayOptionsHelp() {
    optionList.forEach((k,v) =>   print("${k} :  ${v}"));
    exit(0);
  }
  bool setOption(String option, [String value = null]) {
    bool valueUsed = true;

    switch (option) {
      case '-?': 
        displayOptionsHelp();
        valueUsed = false;
        break;
      case '-d': 
        valueUsed = false;
        debugMessage = true;
        break;
      case '-h': 
        host = value;
        break;
      case '-p': 
        port = int.parse(value);
        break;
      case '--url':
        url = value;
        break;
      case '-c':
        clientID = value;
        break;
      case '-i':
        messageID = int.parse(value);
        break;
      case '-t': 
        topic = value;
        break;
      case '-m': 
        payload = value;
        break;
      case '-q': 
        QoS = int.parse(value);
        break;
      case '-r':
        valueUsed = false;
        retain = true;
        break;
      case '-u': 
        user = value;
        break;
      case '-P': 
        password = value;
        break;
      case '--will-payload': 
        willPayload = value;
        break;
      case '--will-qos': 
        willQoS = int.parse(value);
        break;
      case '--will-retain': 
        valueUsed = false;
        willRetain = true;
        break;
      case '--will-topic':
        willTopic = value;
        break;
      default: 
          print("Unknown option $option");
          displayOptionsHelp();
          exit(-1);
         break;
    }
    
    return valueUsed;
  }
    
}
main() {
  Options options = new Options();
  MqttPubOptions mqttOptions = new MqttPubOptions();
  
  for (int i=0; i < options.arguments.length; i++) {
    if (options.arguments[i].startsWith("-") && MqttPubOptions.optionList.containsKey(options.arguments[i])) {
      if (mqttOptions.setOption(options.arguments[i], ( (options.arguments.length > i + 1) ? options.arguments[i+1] : null ) ) ) {
        i++;
      }
    }
  }
  
  VirtualMqttConnection mqttCnx;
  
  if (mqttOptions.url == null) {  // socket connection
    mqttCnx = new MqttConnectionIOSocket.setOptions(host:mqttOptions.host, port: mqttOptions.port);
  } else {            // websocket connection
    mqttCnx = new MqttConnectionIOWebSocket.setOptions(mqttOptions.url);
  }
  
  // Create MqttClient
  MqttClient c = new MqttClient(mqttCnx,clientID: mqttOptions.clientID, qos: mqttOptions.QoS);
  
  // set additional options
  c.debugMessage = mqttOptions.debugMessage;
  
  if (mqttOptions.willTopic != null) {
    c.setWill(mqttOptions.willTopic, mqttOptions.willPayload, qos:mqttOptions.willQoS, retain:mqttOptions.willRetain);
  }
  // connect to broker
  c.connect(onConnectionLost)
    .then( (c)=> publish(c, mqttOptions)) 
    .catchError((e) => print("Error: $e"), test: (e) => e is SocketException)  
    .catchError((mqttErr) {
      print("Error: $mqttErr");
      exit(-1);
    });  

}

void publish(MqttClient c, MqttPubOptions mqttOptions) {
  c.publish(mqttOptions.topic, mqttOptions.payload, mqttOptions.messageID, mqttOptions.QoS, mqttOptions.retain)
      .then( (m) {
        print("Message ${m.messageID} published");
        if (mqttOptions.willTopic == null) {    // if a WILL is defined, don't disconnect to have the will sent
          c.disconnect();
        }
      });
}
void onConnectionLost() {
  print("Connection lost");
}