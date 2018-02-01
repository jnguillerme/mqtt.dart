part of mqtt_shared;

final num KEEPALIVE = 30;

/**
 * mqttMessage
 * This abstract class describes an mqttMessage
 * It will be extended for each specific mqtt message (CONNECT, PUBLISH ...)
 */
abstract class MqttMessage {  
  List<int> _buf;
  List<int> get buf => _buf;
  
  int type;
  num len;
  int QoS;
  int DUP;
  int retain;
  
  /**
   * default constructor
   */
  MqttMessage(this.type, [this.len = 0]) : QoS = QOS_0, DUP = 0, retain = 0 {
    _buf = new List<int>();
  }
  /**
   * setOptions constructor
   * Set the message options 
   */
  MqttMessage.setOptions(this.type, this.len, [this.QoS = 0, this.retain = 0]) : DUP = 0 {
    _buf = new List<int>();
  }
  
  /**
   * decode constructor
   * Decode data to initialize the mqtt message
   * 
   * a message is made of
   *    - a fixed header
   *    - a variable header (message specific)
   *    - a payload (message specific)
   */
  MqttMessage.decode(List<int> data, [bool debugMessage = false]) {
    num fhLen = decodeFixedHeader(data);
    num vhLen = decodeVariableHeader(data.sublist(fhLen), fhLen);
    if (data.length > fhLen + vhLen) {
      decodePayload(data.sublist(fhLen + vhLen));
    }
    
    if (debugMessage) {
      print("<<< ${this.toString()}");
    }
  }

  String toString() {
    String bufString = "";
    if (_buf != null) {
      _buf.forEach( (b) => bufString = bufString + b.toString());
    }
    return "Type(${type}) Len(${len}) QoS(${QoS}) DUP(${DUP}) retain(${retain}) <${bufString}>]";
  }
  /**
   * operator ==
   */
  bool operator == (MqttMessage other) {
    return ( type == other.type
          && len == other.len
          && QoS == other.QoS
          && DUP == other.DUP
          && retain == other.retain
    );
  }
  /**
   * encode
   * encode a mqtt message
   * a message is made of
   *    - a fixed header
   *    - a variable header (message specific)
   *    - a payload (message specific)
   */
  encode() {
    encodeFixedHeader();
    encodeVariableHeader();
    encodePayload();
    len = _buf.length;
  }

  /**
   * encodeFixedHeader
   * Build the 2 bytes mqtt Fixed header
   * Byte 1 :
   *    bit 7 - 4 : Message type
   *    bit 3     : DUP flag
   *    bit 2 - 1 : Qos Level
   *    bit 0     : RETAIN
   * 
   * Byte 2 : Remaining length
   */
  encodeFixedHeader() {    
    _buf.add( ((type << 4) | (DUP << 3) | (QoS << 1) | retain) );   // byte 1
    
    // byte 2 - encode remaining length
    if (len > 2) {
      num remLen = len - 2;
      int digit;
      do {
        digit = remLen % 128;
        remLen = remLen ~/ 128;
        if ( remLen > 0 ) {
          digit = (digit | 0x80);
        }
        _buf.add(digit);                                                  
      } while (remLen > 0);
    }
    else {
      _buf.add(0);
    }
  }
  /**
   * encodeVariableHeader
   * Message specific - to be defined in extended classes
   */
  encodeVariableHeader() {}
  
  /**
   * encodePayload
   * Message specific (Optional) - to be defined in extended classes
   */
  encodePayload() {}  

   
  /** 
   * decodeFixedHeader
   * Decode the 2 byte mqtt fixed header
   * Byte 1 :
   *    bit 7 - 4 : Message type
   *    bit 3     : DUP flag
   *    bit 2 - 1 : Qos Level
   *    bit 0     : RETAIN
   * 
   * Byte 2 : Remaining length  
   * 
   * Returns length of fixed header. 
   */
  num decodeFixedHeader(data) {
    type = data[0] >> 4;
    DUP = data[0] & 0x1000;
    QoS = (data[0]>>1) & QOS_ALL;
    retain = data[0] & 0x01;
    
    num pos = 1;
    int digit;
    num remLength = 0;
    num multiplier = 1;
    
    // remaining length
    do {
      digit = data[pos++];
      remLength += ((digit & 127) * multiplier);
      multiplier *= 128;  
    } while ( (digit & 0x80) != 0);

    len = remLength + pos;

    return pos;
  }

  /**
   * decodeVariableHeader
   * Message specific - to be defined in extended classes
   *
   * Return the length of the variable header
   */
  num decodeVariableHeader(List<int> data, int fhLen) { return 0; }
  
  /**
   * decodePayload
   * Message specific (Optional) - to be defined in extended classes
   */
  decodePayload(List<int> data) {}
}



