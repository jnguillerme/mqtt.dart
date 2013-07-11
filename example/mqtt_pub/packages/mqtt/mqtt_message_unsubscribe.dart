part of mqtt_shared;

/**
 * mqttMessageUnsubscribe
 * 
 * MQTT UNSUBSCRIBE message
 * 
 */
class MqttMessageUnsubscribe extends MqttMessage {
  String _topic;
  num _messageID;
  
  MqttMessageUnsubscribe.setOptions(String topic, num messageID) : this._topic = topic, this._messageID = messageID, super.setOptions(UNSUBSCRIBE, 4 + topic.length, QOS_1);
  
  /**
   * encodeVariableHeader
   * encode variable header for SUBSCRIBE message
   * byte 1 - Message ID MSB
   * byte 2 - Message ID LSB
   */
  encodeVariableHeader() {
    //variable header
    _buf.add(_messageID ~/ 256);
    _buf.add(_messageID % 256);
  }
  
  /**
   * encodePayload
   * encode payload for SUBSCRIBE message
   * byte 1 - topic length MSB
   * byte 2 - topic length LSB
   * byte 3 -> 2 + 3 + topicLength: topic
   */
  encodePayload() {
    // payload
    _buf.add(_topic.length ~/ 256);
    _buf.add(_topic.length % 256);
    
    _buf.addAll(encodeUtf8(_topic));    
  }
}
