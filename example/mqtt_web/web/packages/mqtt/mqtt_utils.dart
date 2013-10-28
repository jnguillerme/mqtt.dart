/**
 * mqttConst.dart
 * Define constants required by mqtt Protocol
 */
part of mqtt_shared;

/**
 * mqttMessageType
 * Define all possible mqtt message types
 */
const int RESERVED = 0;
const int CONNECT = 1;
const int CONNACK = 2;
const int PUBLISH = 3;
const int PUBACK = 4;
const int PUBREC = 5;
const int PUBREL = 6;
const int PUBCOMP = 7;
const int SUBSCRIBE = 8;
const int SUBACK = 9;
const int UNSUBSCRIBE = 10;
const int UNSUBACK = 11;
const int PINGREQ = 12;
const int PINGRESP = 13;
const int DISCONNECT = 14;
  

/**
 * mqttConnackRC
 * CONNACK Return codes 
 */
class MqttConnackRC {
  static final RCs = [  "Connection Accepted",                              // 0
                        "Connection Refused: unacceptable protocol version", // 1,
                        "Connection Refused: identifier rejected",          // 2
                        "Connection Refused: server unavailable",           // 3
                        "Connection Refused: bad user name or password",    // 4
                        "Connection Refused: not authorized"];              // 5

  const MqttConnackRC();
  
  static String decodeConnackRC(num RC) {
    String rcMsg = RCs[RC];
    return (rcMsg != null) ? rcMsg : "Connection return code unknown $RC";
  }
}

/**
 * mqttQosLevel
 * Qos Level
 */
const int QOS_0 = 0x00;
const int QOS_1 = 0x01;
const int QOS_2 = 0x02;
const int QOS_ALL = 0x03;

class MqttError {
  const MqttError();
}

