import 'dart:io';
import 'package:mqtt/mqtt_shared.dart';
import 'package:mqtt/mqtt_connection_io_socket.dart';
import 'package:mqtt/mqtt_connection_io_websocket.dart';
import 'package:args/args.dart';

/**
 * mqtt_pub
 * Sample file showing how to use the mqtt lib
 *
 * options
 *  -h, --help display help message
 *  -d enable debug message
 *  -H host to connect to. Default is 127.0.0.1
 *  -P port to connect to. Default is 1883
 *  --url broker url for websocket connection
 *  -c clienID
 *  -i messageID
 *  -t topic
 *  -m message payload
 *  -q quality of service. Default is 0
 *  -r message should be retained
 *  -u provide a username
 *  -p provide a password
 *  --willMessage payload for the client will
 *  --willQos  quality of service for the client will
 *  --willRetain if provided, make the client will retain
 *  --willTopic the topic on which to publish the client will
 *
 *  [ADD CERTICATE / ENCRYPTION support]
 *
 */

class MqttPubOptions {


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

  ArgParser argParser() {

    var parser = new ArgParser();

    void _help(bool value) {
      if(value) {
        print(parser.getUsage());
        exit(0);
      }
    }

    parser.addFlag(
        "help",
        abbr:"h",
        help:"Prints this help.",
        negatable:false,
        callback:_help
      );

    parser.addFlag('debug',
                       abbr: 'd',
                       help: 'enable debug message',
                       callback: (d) => debugMessage = d);

    parser.addOption('mqttHost',
                      abbr:'H',
                      defaultsTo: '127.0.0.1',
                      help: 'Mqtt broker host to connect to',
                      callback: (h) => host = h);

    parser.addOption('mqttPort',
                      abbr:'P',
                      defaultsTo: '1883',
                      help: 'Mqtt broker port to connect to',
                      callback: (p) => port = int.parse(p));

    parser.addOption('mqttUrl',
                      abbr:'U',
                      defaultsTo: null,
                      help: 'Mqtt broker url for websocket connection',
                      callback: (u) => url = u);

    parser.addOption('clientId',
                      abbr:'i',
                      defaultsTo: 'mqtt_dart_pub',
                      help: 'client Id',
                      callback: (id) => clientID = id);

    parser.addOption('messageId',
                      abbr:'n',
                      defaultsTo: '0',
                      help: 'Message Id',
                      callback: (id) => messageID = int.parse(id));

    parser.addOption('topic',
                      abbr:'t',
                      help: 'Topic',
                      callback: (t) => topic = t);

    parser.addOption('message',
                      abbr:'m',
                      help: 'Message',
                      callback: (m) => payload = m);

    parser.addOption('qos',
                      abbr:'q',
                      defaultsTo: '0',
                      help: 'quality of service',
                      callback: (q) => QoS = int.parse(q));

    parser.addFlag('retain',
                      abbr: 'r',
                      defaultsTo: false,
                      help: 'message should be retained',
                      callback: (r) => retain = r );

    parser.addOption('user',
                      abbr:'u',
                      help: 'username',
                      callback: (u) => user = u);

    parser.addOption('password',
                      abbr:'p',
                      help: 'password',
                      callback: (p) => password = p);

    parser.addOption('willTopic',
                      abbr:'T',
                      help: 'payload for the client will',
                      callback: (wt) => willTopic = wt);

    parser.addOption('willMessage',
                      abbr:'M',
                      help: 'topic for the client will',
                      callback: (wp) => willPayload = wp);

    parser.addOption('willQos',
                      abbr:'Q',
                      defaultsTo: '0',
                      help: 'quality of service for the client will',
                      callback: (wq) => willQoS = int.parse(wq));

    parser.addFlag('willRetain',
                      abbr: 'R',
                      defaultsTo: false,
                      help: 'make the client will retain',
                      callback: (wr) => willRetain = wr );

    return parser;
   }

}

main(List<String> args) {
  print("starting");

  MqttPubOptions mqttOptions = new MqttPubOptions();
  ArgParser a = mqttOptions.argParser();

  if (a != null) {
      a.parse(args);
  } else {
      print("Error ! no arg parser !");
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
    .then( (ret) => publish(c, mqttOptions))
    .catchError((e) => print("Error: $e"), test: (e) => e is SocketException)
    .catchError((mqttErr) {
      print("Error: $mqttErr");
      exit(-1);
    });

}

void publish(MqttClient c, MqttPubOptions mqttOptions) {
  c.publish(mqttOptions.topic, mqttOptions.payload, mqttOptions.messageID, mqttOptions.QoS, mqttOptions.retain)
      .then( (m) {
          print("published !");
        print("Message ${m.messageID} published");
        if (mqttOptions.willTopic == null) {    // if a WILL is defined, don't disconnect to have the will sent
          c.disconnect();
        }
      });
}
void onConnectionLost() {
  print("Connection lost");
}
