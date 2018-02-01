part of mqtt_shared;

/**
 * MqttMessageConnack
 * 
 * MQTT CONNACK message
 * 
 */
class MqttMessageConnack extends MqttMessage {

  String connAckStatus = "unknown";
  num returnCode;
  
  MqttMessageConnack.decode(List<int> data, [bool debugMessage = false]) : super.decode(data, debugMessage);

  
  /**
   * decodeVariableHeader
   * Decode CONNACK variable header
   *  byte 1 - reserved value. Not used
   *  byte 2 - return code
   */
  num decodeVariableHeader(List<int> data, int fhLen) {
    assert(data.length == 2);
    
    returnCode = data[1];
    
    connAckStatus = MqttConnackRC.decodeConnackRC(data[1]);
    return 2;      
  }
  
}
