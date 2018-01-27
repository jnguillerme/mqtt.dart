part of mqtt_shared;

/**
 * MqttMessageSuback
 * 
 * MQTT SUBACK message
 * 
 */
class MqttMessageSuback extends MqttMessageAssured {

  num messageID;
  int grantedQoS;
  
  MqttMessageSuback() : messageID = 0, grantedQoS = 0, super(SUBACK);
  MqttMessageSuback.decode(List<int> data, [bool debugMessage = false]) : messageID = 0, grantedQoS = QOS_0, super.decode(data, debugMessage);

  /**
   * decodeVariableHeader
   * Decode SUBACK variable header
   * The variable header contains the Message ID for the SUBSCRIBE message that is being acknowledged
   *  byte 1 - Message ID MSB
   *  byte 2 - Message ID LSB
   */
  num decodeVariableHeader(List<int> data, int fhLen) {
    // assert(data.length == 3);
    
    messageID = 256 * data[0] + data[1];

    return 2;      
  }
  
  /**
   * decodePayload
   * Decode PUBACK payload
   * The payload is one byte long and contains a vector of granted QoS levels
   *  bit 7 - 2 : Reserved
   *  bit 1 - 0 : Granted QoS Level
   */
  decodePayload(List<int> data) {
    grantedQoS = (data[0] & QOS_ALL);
    print("[Suback] Granted QOS level: $grantedQoS");
  }  

}
