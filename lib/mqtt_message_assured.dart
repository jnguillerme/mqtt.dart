part of mqtt_shared;

/////
// Describe the Assured publish messages
//    PUBACK
//    PART 1 - PUBREC
//    PART 2 - PUBREL
//    PART 3 - PUBCOMP
//////

/**
 * MqttMessageAssuredPublish
 * 
 * MQTT Assured Publish base class
 * 
 */
abstract class MqttMessageAssured extends MqttMessage {

  int _msgID_MSB;
  int _msgID_LSB;
  
  get messageID => (256 * _msgID_MSB + _msgID_LSB);

  MqttMessageAssured(num type, [this._msgID_MSB =0 , this._msgID_LSB = 0]) : super(type, 4);
  MqttMessageAssured.initWithMessageID(num type, num theMessageID) :   _msgID_MSB = theMessageID ~/ 256, 
                                                  _msgID_LSB = theMessageID % 256,
                                                  super(type);
  MqttMessageAssured.decode(List<int> data, [bool debugMessage = false]) : _msgID_MSB = 0, _msgID_LSB = 0, super.decode(data, debugMessage);

  /**
   * decodeVariableHeader
   * Decode variable header
   * The variable header contains the Message ID for the PUBLISH message that is being acknowledged
   *  byte 1 - Message ID MSB
   *  byte 2 - Message ID LSB
   */
  num decodeVariableHeader(List<int> data, int fhLen) {
    assert(data.length == 2);
    
    _msgID_MSB = data[0];
    _msgID_LSB = data[1];

    return 2;      
  }
 
  /**
   * encodeVariableHeader
   * 
   */
  encodeVariableHeader() {
    // message ID
    _buf.add(_msgID_MSB);
    _buf.add(_msgID_LSB); 
  }
}

/**
 * MqttMessagePuback
 * 
 * MQTT PUBACK message
 * 
 */
class MqttMessagePuback extends MqttMessageAssured {
  
  MqttMessagePuback(int msgID_MSB, int msgID_LSB) : super(PUBACK, msgID_MSB, msgID_LSB);
  MqttMessagePuback.initWithMessageID(num theMessageID) :  super.initWithMessageID(PUBACK, theMessageID);
  MqttMessagePuback.initWithPublishMessage(MqttMessagePublish m) : super(PUBACK, m._msgID_MSB, m._msgID_LSB);
  MqttMessagePuback.decode(List<int> data, [bool debugMessage = false]) : super.decode(data, debugMessage);

}

/**
 * MqttMessagePubrec
 * 
 * MQTT PUBREC message (Assured Publish Received - part 1)
 * 
 */
class MqttMessagePubrec extends MqttMessageAssured {  
  MqttMessagePubrec(int msgID_MSB, int msgID_LSB) : super(PUBREC, msgID_MSB, msgID_LSB);
  MqttMessagePubrec.initWithPublishMessage(MqttMessagePublish m) : super(PUBREC, m._msgID_MSB, m._msgID_LSB);
  MqttMessagePubrec.decode(List<int> data, [bool debugMessage = false]) : super.decode(data, debugMessage);
}

/**
 * MqttMessagePubrel
 * 
 * MQTT PUBREL message (Assured Publish Release - part 2)
 * 
 */
class MqttMessagePubrel extends MqttMessageAssured {  
  MqttMessagePubrel(int msgID_MSB, int msgID_LSB) : super(PUBREL, msgID_MSB, msgID_LSB);
  MqttMessagePubrel.initWithPubRecMessage(MqttMessagePubrec m): super(PUBREL, m._msgID_MSB, m._msgID_LSB);
  MqttMessagePubrel.decode(List<int> data, [bool debugMessage = false]) : super.decode(data, debugMessage);
}

/**
 * MqttMessagePubcomp
 * 
 * MQTT PUBREL message (Assured Publish Complete - part 3)
 * 
 */
class MqttMessagePubcomp extends MqttMessageAssured {  
  MqttMessagePubcomp(int msgID_MSB, int msgID_LSB) : super(PUBCOMP, msgID_MSB, msgID_LSB);
  MqttMessagePubcomp.initWithPubRelMessage(MqttMessagePubrel m): super(PUBCOMP, m._msgID_MSB, m._msgID_LSB);
  MqttMessagePubcomp.decode(List<int> data, [bool debugMessage = false]) : super.decode(data, debugMessage);
}
