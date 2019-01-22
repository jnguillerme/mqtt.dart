import 'dart:io';
import 'package:mqtt/mqtt_shared.dart';
import 'package:mqtt/mqtt_connection_io_socket.dart';
import 'package:args/args.dart';

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

  ArgParser argParser() {

    var parser = new ArgParser();

    void _help(bool value) {
      if(value) {
        print(parser.getUsage());
        exit(0);
      }
    }
    void _topic(var t) {
      topic = t;
    }
    parser.addFlag(
        "help",
        abbr:"h",
        help:"Prints this help.",
        negatable:false,
        callback:_help
      );
    parser.addFlag('clean',
                    abbr: 'c',
                    defaultsTo: true,
                    help: 'enable clean session',
                    callback: (c) => cleanSession = c);

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

    parser.addOption('clientId',
                      abbr:'i',
                      defaultsTo: 'mqtt_dart_sub',
                      help: 'client ID',
                      callback: (id) => clientID = id);

    parser.addOption('keepAlive',
                      abbr:'k',
                      defaultsTo: '61',
                      help: 'keep alive in seconds',
                      callback: (k) => keepAlive = int.parse(k));

    parser.addOption('topic',
                      abbr:'t',
                      help: 'topic',
                      callback: (t) => _topic(t));

    parser.addOption('qos',
                      abbr:'q',
                      defaultsTo: '0',
                      help: 'quality of service',
                      callback: (q) => QoS = int.parse(q));

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
                      help: 'Topic for the client will',
                      callback: (wt) => willTopic = wt);

    parser.addOption('willMessage',
                      abbr:'M',
                      help: 'Message for the client will',
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
  MqttSubOptions mqttOptions = new MqttSubOptions();
  mqttOptions.argParser().parse(args);

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
    .then( (ret) => subscribe(c, mqttOptions))
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
