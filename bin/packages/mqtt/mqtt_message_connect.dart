part of mqtt_shared;



/** 
 * mqttWill
 * Define mqttWill
 */
class MqttWill {
  String topic;
  String payload;
  int qos;
  int retain;
  
  MqttWill(this.topic, this.payload, this.qos, this.retain);
}


/**
 * mqttMessageConnect
 * 
 * MQTT CONNECT message
 * 
 */
class MqttMessageConnect extends MqttMessage {
  int _cleanSession = 0;
  String _clientID;
  MqttWill _will = null;
  String _userName = null;
  String _password = null;
  
  MqttMessageConnect.setOptions(String clientID, int qos, bool cleanSession) 
        : this._clientID = clientID,
          this._cleanSession = (cleanSession ? 1 : 0),
          super.setOptions(CONNECT, 16 + clientID.length, qos);
    
  /**
   * setWill
   * Set will for the connection
   * Must be call before connecting to mqtt broker
   */
  void setWill(MqttWill w) {
    if (w != null) {
      _will = w;
      len += 4 + encodeUtf8(_will.topic).length + encodeUtf8(_will.payload).length;
    }
  }
  
  
  /**
   * setUserName
   */
  void setUserName(String userName) {
    if (_userName != null) {
      _userName = userName;
      len += 2 + encodeUtf8(_userName).length;
    }
  }
  
  /**
   * setUserNameAndPassword
   */
  void setUserNameAndPassword(String userName,String password) {
    setUserName(_userName);
   
    if (password != null) {
      _password = password;
      len += 2 + encodeUtf8(_password).length;
    }
  }
  
  /**
   * buildVariableHeader for CONNECT message
   * 
   * byte 1 - Length MSB (0)
   * byte 2 - Length LSB (6)
   * byte 3 - 'M'
   * byte 4 - 'Q'
   * byte 5 - 'I'
   * byte 6 - 's'
   * byte 7 - 'd'
   * byte 8 - 'p'
   * byte 9 - Protocol version
   * byte 10 - Connect flags
   *    bit 0 - reserved
   *    bit 1 - Clean session
   *    bit 2 - Will Flag
   *    bit 3 - Will Qos
   *    bit 4 - Will Retain
   *    bit 5 - Password Flag
   *    bit 6 - User name Flag
   *    
   * byte 11 - Keep Alive MSB    
   * byte 12 - Keep Alive LSB
   *     
   */
  encodeVariableHeader() {

    _buf.add(0x00);     // length MSB
    _buf.add(0x06);     // length LSB
    
    _buf.addAll(MQTT_VERSION_IDENTIFIER);   // protocol name
    _buf.add(MQTT_VERSION);         // protocol version
    
    // CONNECT flag
    int connectFlag = 0x00; 
  
    //clean flag
    connectFlag |= (_cleanSession << 1);    
  
    // will flag
    if (_will != null) {    
      connectFlag |=  ( 0x04 |( _will.qos << 3) | (_will.retain << 5));
    }
    
    // user /password flag
    int userFlag = (_userName != null) ? 1 : 0;
    int passwordFlag = (_password != null) ? 1 : 0;
    connectFlag |= ( userFlag << 6) | ( passwordFlag <<7 ); 
  
    _buf.add(connectFlag);  

    //Keep alive Timer
    _buf.add(0x00);
    _buf.add(KEEPALIVE);  //Keepalive for 30s
  }
  
  /**
   * encodePayload
   * encode payload for CONNECT message. It consists of:
   *  - Client Identifier
   *  - Will Topic
   *  - Will Message
   *  - User Name
   *  - Password
   */
  encodePayload() {
  
    //num payloadLen = len - 14;    
   
    // client identifier  
    _buf.add(encodeUtf8(_clientID).length ~/ 256);
    _buf.add(encodeUtf8(_clientID).length % 256);  
    _buf.addAll(encodeUtf8(_clientID));
    
    if (_will != null) {
      _buf.add(encodeUtf8(_will.topic).length ~/ 256);
      _buf.add(encodeUtf8(_will.topic).length % 256);  
      _buf.addAll(encodeUtf8(_will.topic));

      _buf.add(encodeUtf8(_will.payload).length ~/ 256);
      _buf.add(encodeUtf8(_will.payload).length % 256);  
      _buf.addAll(encodeUtf8(_will.payload));      
    }
    
    if (_userName != null) {
      _buf.add(encodeUtf8(_userName).length ~/ 256);
      _buf.add(encodeUtf8(_userName).length % 256);  
      _buf.addAll(encodeUtf8(_userName));            
    }

    if (_password != null) {
      _buf.add(encodeUtf8(_password).length ~/ 256);
      _buf.add(encodeUtf8(_password).length % 256);  
      _buf.addAll(encodeUtf8(_password));            
    }

  }
  
}
