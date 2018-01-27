part of mqtt_shared;

/**
 * MqttMessageUnsuback
 * 
 * MQTT UNSUBACK message
 * 
 */
class MqttMessageUnsuback extends MqttMessageAssured {

  num messageID;
  
  MqttMessageUnsuback() : messageID = 0, super(UNSUBACK);
  MqttMessageUnsuback.decode(List<int> data, [bool debugMessage = false]) : messageID = 0, super.decode(data, debugMessage);

  /**
   * decodeVariableHeader
   * Decode UNSUBACK variable header
   * The variable header contains the Message ID for the UNSUBSCRIBE message that is being acknowledged
   *  byte 1 - Message ID MSB
   *  byte 2 - Message ID LSB
   */
  num decodeVariableHeader(List<int> data, int fhLen) {
    assert(data.length == 2);
    
    messageID = 256 * data[0] + data[1];

    return 2;      
  }
  
}
