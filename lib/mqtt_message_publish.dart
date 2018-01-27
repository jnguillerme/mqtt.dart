part of mqtt_shared;

/**
 * MqttMessagePublish
 * 
 * MQTT PUBLISH message
 * 
 */
class MqttMessagePublish extends MqttMessage {

  int _msgID_MSB;  
  int _msgID_LSB;
  get messageID => (256 * _msgID_MSB + _msgID_LSB);
  
  String _topic;
  String _payload;
  
  int _payloadPos;

  /// Constructors
  MqttMessagePublish.setOptions(String topic, String payload, [num msgID = 1, int QoS = 0, int retain = 0]) : 
                                                this._topic = topic, this._payload = payload,
                                                this._msgID_MSB = ((QoS > 0) ? (msgID ~/ 256) : 0), 
                                                this._msgID_LSB = ((QoS > 0) ? (msgID % 256) : 0),
                                                super.setOptions(PUBLISH, (QoS > 0) ? (6 + UTF8.encode(topic).length + UTF8.encode(payload).length) 
                                                                                    : (4 + UTF8.encode(topic).length + UTF8.encode(payload).length), 
                                                                         QoS, retain);
  
  MqttMessagePublish.decode(List<int> data, [bool debugMessage = false]) : _msgID_MSB = 0, _msgID_LSB = 0, _payload = "", _payloadPos =0,  super.decode(data, debugMessage);
  
  bool operator == (MqttMessagePublish other) {
        return ( super==(other) 
          && _msgID_MSB == other._msgID_MSB
          && _msgID_LSB == other._msgID_LSB
          && _topic == other._topic
          && _payload == other._payload  
      );      
  }
  /// methods
  /**
   * encodeVariableHeader
   * encode Variable header for PUBLISH message
   * 
   * topic name -----------------------------
   * byte 1 : topic length MSB
   * byte 2 : topic length LSB
   * byte 3 -> topic length : topic name
   * Msg ID ----------------------------------
   * byte topic length + 2 : message ID MSB
   * byte topic length + 3 : message ID LSB
   */
  encodeVariableHeader() {
    // get topic length MSG and LSB
    _buf.add(_topic.length ~/ 256);
    _buf.add(_topic.length % 256);
    
    // add topic    
    _buf.addAll(UTF8.encode(_topic));
    
    // msg ID - only required for QoS 1 or 2
    if (QoS > 0) {
      _buf.add(_msgID_MSB);
      _buf.add(_msgID_LSB);
    }
  }
  
  encodePayload() {
    // payload
    _buf.addAll(UTF8.encode(_payload));
  }

  /**
   * decodeVariableHeader
   * decode PUBLISH variable header
   * 
   * topic name -----------------------------
   * byte 1 : topic length MSB
   * byte 2 : topic length LSB
   * byte 3 -> topic length : topic name
   * Msg ID ----------------------------------
   * byte topic length + 2 : message ID MSB
   * byte topic length + 3 : message ID LSB
   *
   * Return the length of the variable header
   */
  num decodeVariableHeader(List<int> data, int fhLen)   {
    int pos = 0;
    num topicLength = 256 * data[pos++] + data[pos++];
    
    _topic = UTF8.decode(data.sublist(pos, topicLength+pos));
    pos += topicLength;
    
    if (QoS > 0) {      // QOS 1 and 2 include a message ID
      _msgID_MSB = data[pos++];
      _msgID_LSB = data[pos++];
    }  
    
    _payloadPos = fhLen + pos;      // position for the 1st payload character = 2 (fixed header length) + pos (variable header length) 
    
    return pos;
  }
  
  /**
   * decodePayload
   * Message specific (Optional) - to be defined in extended classes
   */
  decodePayload(List<int> data) {
    int payloadLen = len - _payloadPos;
    
    if (payloadLen <= data.length) {
      _payload = UTF8.decode(data.sublist(0, payloadLen) );
    } else {
      print("WARNING: Payload is truncated - Characters received: ${data.length} - expected: ${payloadLen} "); 
      _payload = UTF8.decode(data);
    }
  }  
}
