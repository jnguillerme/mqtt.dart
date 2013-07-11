import 'dart:io';
import 'package:mqtt/mqtt_shared.dart';
import 'package:mqtt/mqtt_connection_io_socket.dart';

/**
 * mqtt_sub
 * Sample file showing how to use the mqtt lib
 * 
 * options
 *  -?, --help display help message
 *  -c disable clean session
 *  -d enable debug message
 *  -h host to connect to. Default is 127.0.0.1
 *  -p port to connect to. Default is 1883
 *  -i clienID
 *  -k keep alive in seconds for this client - defaults to 60
 *  -t topic
 *  -m message payload
 *  -q quality of service. Default is 0
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

class MqttSubOptions {
  static Map<String, String> optionList = {
                        '-?': 'display help message',
                        '-c': 'disable clean session',
                        '-d': 'enable debug message',
                        '-h': 'host to connect to. Default is 127.0.0.1',
                        '-p': 'port to connect to. Default is 1883',
                        '-i': 'client ID',
                        '-k': 'keep alive in seconds. Defaults is 60',
                        '-t': 'topic',
                        '-m': 'message payload',
                        '-q': 'quality of service. Default is 0',
                        '-u': 'provide a username',
                        '-P': 'provide a password',
                        '--will-payload': 'payload for the client will',
                        '--will-qos': 'quality of service for the client will',
                        '--will-retain': 'if provided, make the client will retain',
                        '--will-topic': 'the topic on which to publish the client will'};
  
  bool debugMessage = false;
  bool cleanSession = true;
  String host = '127.0.0.1';
  num port= 1883;
  String clientID = "mqtt_dart_sub";
  num keepAlive = 60;
  String topic;
  String payload;
  int QoS = QOS_0;
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
      case '-c': 
        valueUsed = false;
        cleanSession = false;
        break;
      case '-h': 
        host = value;
        break;
      case '-p': 
        port = int.parse(value);
        break;
      case '-i':
        clientID = value;
        break;
      case '-k':
        keepAlive = int.parse(value);
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
  MqttSubOptions mqttOptions = new MqttSubOptions();
  
  for (int i=0; i < options.arguments.length; i++) {
    if (options.arguments[i].startsWith("-") && MqttSubOptions.optionList.containsKey(options.arguments[i])) {
      if (mqttOptions.setOption(options.arguments[i], ( (options.arguments.length > i + 1) ? options.arguments[i+1] : null ) ) ) {
        i++;
      }
    }
  }
  
  // Create MqttClient
  MqttClient<MqttConnectionIOSocket> c = new MqttClient(new MqttConnectionIOSocket.setOptions(host:mqttOptions.host, port: mqttOptions.port), 
                                clientID: mqttOptions.clientID, 
                                qos: mqttOptions.QoS,
                                cleanSession: mqttOptions.cleanSession);
  
  // set additional options
  c.debugMessage = mqttOptions.debugMessage;
  
  if (mqttOptions.willTopic != null) {
    c.setWill(mqttOptions.willTopic, mqttOptions.willPayload, qos:mqttOptions.willQoS, retain:mqttOptions.willRetain);
  }
  // connect to broker
  c.connect(onConnectionLost)
    .then( (c)=> subscribe(c, mqttOptions)) 
    .catchError((e) => print("Error: $e"), test: (e) => e is SocketException)  
    .catchError((mqttErr) {
      print("Error: $mqttErr");
      exit(-1);
    });  
  
}

void subscribe(MqttClient c, MqttSubOptions mqttOptions) {
  c.subscribe(mqttOptions.topic, mqttOptions.QoS, (t, d) => print("[$t] $d"))
      .then( (s) => print("Subscription done - ID: ${s.messageID} - Qos: ${s.grantedQoS}"));
;
}
void onConnectionLost() {
  print("Connection lost");
}