part of mqtt_shared;

/**
 * mqttMessageSubscribe
 * 
 * MQTT SUBSCRIBE message
 * 
 */
class MqttMessageSubscribe extends MqttMessage {
  String _topic;
  num _messageID;
  
  MqttMessageSubscribe.setOptions(String topic, num messageID, int QoS) 
              : this._topic = topic, this._messageID = messageID, super.setOptions(SUBSCRIBE, 7 + topic.length, QoS);
  
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
   * byte 2 + 3 + topicLength + 1 : Requested QoS 
   */
  encodePayload() {
    // payload
    _buf.add(_topic.length ~/ 256);
    _buf.add(_topic.length % 256);
    
    _buf.addAll(UTF8.encode(_topic));
    
    // QoS level
    _buf.add(QoS);

  }
}

