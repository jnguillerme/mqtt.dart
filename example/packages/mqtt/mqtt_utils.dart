/**
 * mqttConst.dart
 * Define constants required by mqtt Protocol
 */
part of mqtt_shared;

/**
 * mqttMessageType
 * Define all possible mqtt message types
 */
const num RESERVED = 0;
const num CONNECT = 1;
const num CONNACK = 2;
const num PUBLISH = 3;
const num PUBACK = 4;
const num PUBREC = 5;
const num PUBREL = 6;
const num PUBCOMP = 7;
const num SUBSCRIBE = 8;
const num SUBACK = 9;
const num UNSUBSCRIBE = 10;
const num UNSUBACK = 11;
const num PINGREQ = 12;
const num PINGRESP = 13;
const num DISCONNECT = 14;
  

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

