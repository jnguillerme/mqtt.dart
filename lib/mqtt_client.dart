part of mqtt_shared;


class MqttClient<E extends VirtualMqttConnection> {

  final E _mqttConnection;
  final String _clientID;
  final num _qos;
  final bool _cleanSession;
  Completer  _connack;
  Map<String, Function> _onSubscribeDataMap = null;
  var onConnectionLost = null;
  Map<int, Completer>  _messagesToCompleteMap;
  final String _userName;
  final String _password;
  var _remData;

  var _liveTimer;

  bool debugMessage;
  MqttWill _will;

  /**
   * MqttClient constructor
   */
  MqttClient(E mqttConnection, {String clientID: '', num qos: 0x0, bool cleanSession:true, String userName: null, String password: null} )
              : _mqttConnection = mqttConnection, _clientID = clientID, _qos = qos, _cleanSession = cleanSession, debugMessage = false,
              _will = null, _userName = userName, _password = password;

  /**
   * setWill
   * Set will for the connection
   * Must be call before connecting to mqtt broker
   */
  void setWill(String topic, String message, {int qos: QOS_0, bool retain: false}) {
    _will = new MqttWill(topic, message, qos, (retain ? 1 : 0) );
  }

  /**
   * connect
   * Connect to mqtt broker on address _host and port _port
   * Establish physical connection. Upon successfull completion open mqtt session
   *
   * An optional callback can be provided to be called when
   * the connection to the mqtt broker has been lost
  */
  Future<dynamic> connect([onConnectionLostCallback]) {
    _connack = new Completer();

    if (onConnectionLostCallback != null) onConnectionLost = onConnectionLostCallback;

    _mqttConnection.connect().then( (socket) => _handleConnected(socket))
                    .catchError((e) => _mqttConnection.handleConnectError(e));


     return _connack.future;
  }

  /**
   * disconnect
   * Send DISCONNECT message to mqtt broker
   */
  void disconnect() {
      print("Disconnecting");
      MqttMessageDisconnect m = new MqttMessageDisconnect();
      _mqttConnection.sendMessageToBroker(m, debugMessage);
      _mqttConnection.close();
  }

  /**
   * subscribe
   * subscribe to topic topic with QOS level QOS
   */
  Future<dynamic> subscribe(String topic, int QoS, onSubscribeDataCallback, [num messageID = -1]) {
    print("Subscribe to $topic - QoS: $QoS - Message ID: $messageID");

    if (_onSubscribeDataMap == null)  _onSubscribeDataMap = new Map<String, Function>();

    _onSubscribeDataMap[topic] = onSubscribeDataCallback;
    if (messageID == -1) {
       messageID = _onSubscribeDataMap.length;
       print("Subscribe Message ID: $messageID");
    }
    Completer suback = _addMessageToComplete(messageID, QOS_1, new MqttMessageSuback());   // send as QOS_1 as a SUBACK is expected




    MqttMessageSubscribe m = new MqttMessageSubscribe.setOptions(topic, messageID, QoS);
    _mqttConnection.sendMessageToBroker(m, debugMessage);

    return suback.future;
  }

  /**
   * unsubscribe
   *
   */
  Future<dynamic> unsubscribe(String topic, num messageID) {
    print("Unsubscribe from $topic ($messageID)");
    Completer unsuback = _addMessageToComplete(messageID, QOS_1, new MqttMessageUnsuback()); // send as QOS_1 as a UNSUBACK is expected

    MqttMessageUnsubscribe m = new MqttMessageUnsubscribe.setOptions(topic, messageID);
    _mqttConnection.sendMessageToBroker(m, debugMessage);

    return unsuback.future;
  }

  /**
   * publish
   * publish message with payload to topic with qosLevel
   */
  Future<dynamic> publish(String topic, String payload, [num messageID = 1, int QoS = 0, bool retain = false]) {
    int retainFlag = (retain) ? 1 : 0;
    print("Publish $topic: $payload (ID: $messageID - QoS: $QoS - retain: $retainFlag)");

    Completer puback = _addMessageToComplete(messageID, QoS, new MqttMessagePuback.initWithMessageID(messageID));

    // publish the message
    MqttMessagePublish m = new MqttMessagePublish.setOptions(topic, payload, messageID, QoS, retainFlag);
    _mqttConnection.sendMessageToBroker(m, debugMessage);

    return puback.future;
  }

  /**
   * MqttMessageAssuredPublish
   * add message ID to message to complete map
   */
  Completer _addMessageToComplete(num messageID, int QoS, MqttMessageAssured m) {
    Completer ack = new Completer();

    // for QOS1 and QOS2 messages we expect a PUBACK
    if (QoS > 0) {
      if ( _messagesToCompleteMap == null ) _messagesToCompleteMap = new Map<int, Completer>();

      // messageID must be unique for in flight messages
      if ( _messagesToCompleteMap.containsKey(messageID) ) {
        ack.completeError("Message ID $messageID already in used.");
      } else {
        _messagesToCompleteMap[messageID] = ack;
      }
    } else {      // QOS 0 - no puback will be received
      ack.complete(m);
    }

    return ack;
  }

  void _completeMessage(MqttMessageAssured m, String pubAckType) {
    Completer puback = _messagesToCompleteMap[m.messageID];
    if (puback != null) {
      _messagesToCompleteMap.remove(m.messageID);
      puback.complete(m);
    } else {
      throw("Failed to process ${pubAckType}. Cannot find message to complete for message ID ${m.messageID}");
    }
  }

  /**
   * _handleConnected
   * This method is called when the connection with the mqtt broker
   * has been established
   * It will start listening to messages from the broker and
   * open the mqtt session
   */
  void _handleConnected(cnx) {
    _mqttConnection.setConnection(cnx);
    _mqttConnection.startListening(_processData, _handleDone, _handleError);

     _openSession();
  }
  /**
   * openSession
   * Open mqtt session
   */
   void _openSession() {
     print("Opening session");
     MqttMessageConnect m = new MqttMessageConnect.setOptions(_clientID, _qos, _cleanSession);

     if (_userName != null && _password != null) {
       m.setUserNameAndPassword(_userName, _password);
     }
     // set will
     m.setWill(_will);
     _mqttConnection.sendMessageToBroker(m, debugMessage);
   }

   /**
    * processData
    * This method is called everytime we receive some data
    * from the mqtt broker
    */

   void _processData(data) {
     if (_remData != null) {
       // append data to remaining data
       _remData.addAll(data);
     } else {
       // No remaining data
         if (data is ByteBuffer) {
             _remData = data.asUint8List();
         } else {
             _remData = Uint8List.fromList(data);
         }
     }

     var lenBefore, lenAfter;
     do {
       lenBefore = _remData.length;
       _remData = _processMqttMessage(_remData);
       lenAfter = (_remData != null) ? _remData.length : 0;
     } while (lenBefore != lenAfter && lenAfter >= 2);
   }

   /**
    * _processMqttMessage
    * Process the mqtt message provided in data
    *
    * Return the data that has not been processed
    */
   List<int> _processMqttMessage(data) {
     num type = data[0] >> 4;
     int msgProcessedLength = data.length;

     switch(type) {
      case RESERVED:             //RESERVED do nothing
        break;
      case CONNACK:
        msgProcessedLength = _handleConnack(data);
        break;
      case PUBLISH:
        msgProcessedLength = _handlePublish(data);
        break;
      case PUBACK:
        msgProcessedLength = _handlePuback(data);
        break;
      case PUBREC:
        msgProcessedLength = _handlePubRec(data);
        break;
      case PUBREL:
        msgProcessedLength = _handlePubRel(data);
        break;
      case PUBCOMP:
        msgProcessedLength = _handlePubComp(data);
        break;
      case SUBACK:
        msgProcessedLength = _handleSubAck(data);
        break;
      case UNSUBACK:
        msgProcessedLength = _handleUnsubAck(data);
        break;
      case PINGRESP:            // trace in debug mode?
        break;
      default:
        print("WARNING: Unknown Message type received: $type");
        break;
     }

     return (data.length > msgProcessedLength) ? data.sublist(msgProcessedLength) : null;
   }

   /**
    * done
    * Notification that we got disconnected from the broker
    */
    void _handleDone() {
      print("Connection to broker lost");

      // if live timer was started, cancel it
      if (_liveTimer != null) _liveTimer.cancel();

      // if a connectionLost callback was provided, we call it
      if (onConnectionLost != null) onConnectionLost();
    }

    /**
     * handleError
     *
     */
    void _handleError(e) {
      print("error : $e");
      _connack.completeError(e);
    }

    /**
     * handleConnack
     * handle CONNACK mqtt message
     */
    int _handleConnack(data) {
      MqttMessageConnack m = new MqttMessageConnack.decode(data, debugMessage);

      print("${m.connAckStatus}");

      if (m.returnCode == 0) {      // connection accepted
        _liveTimer = new Timer(const Duration(seconds:25), _live);
        _connack.complete(this);
      } else {                      // connection failed
        _connack.completeError(m.connAckStatus);
      }

      return m.len;
    }

    /**
     * handleSubAck
     * Handle Subscribe ACK message
     */
    int _handleSubAck(data) {
      MqttMessageSuback m = new MqttMessageSuback.decode(data, debugMessage);
      _completeMessage(m, "SUBACK");
      return m.len;
    }

    /**
     * handleUnsubAck
     * Handle unsubscribe ACK message
     */
    int _handleUnsubAck(data) {
      MqttMessageUnsuback m = new MqttMessageUnsuback.decode(data, debugMessage);
      _completeMessage(m, "UNSUBACK");

      return m.len;
    }

    /**
     * handlePublish
     * handle PUBLISH message
     */
    int _handlePublish(data) {
      MqttMessagePublish m = new MqttMessagePublish.decode(data, debugMessage);
      if (m.len > data.length) {
        // Not enough data yet
        return 0;
      }

      // QOS_1 and QOS_2 messages need to be acked
      if (m.QoS > 0) {
        MqttMessageAssured mAck = ((m.QoS == 1)  ? new MqttMessagePuback.initWithPublishMessage(m)
                                                        : new MqttMessagePubrec.initWithPublishMessage(m));
        _mqttConnection.sendMessageToBroker(mAck, debugMessage);
        _resetTimer();
      }

      if (debugMessage) {
        print("[mqttClient] [" + m._topic + "][" + m._payload + "]");
      }
      // notify the client of the new topic / payload
      if (_onSubscribeDataMap != null && _onSubscribeDataMap[m._topic] != null)
        _onSubscribeDataMap[m._topic](m._topic, m._payload);

      return m.len;
    }

    /**
     * _handlePuckAck
     * handle PUBACK message
     */
    int _handlePuback(data) {
      MqttMessagePuback m = new MqttMessagePuback.decode(data, debugMessage);
      _completeMessage(m, "PUBACK");

      return m.len;
    }
     /**
     * handlePubRec
     * handle PUBREC message => send PUBREL back
     */
    int _handlePubRec(data) {
      MqttMessagePubrec mpr = new MqttMessagePubrec.decode(data, debugMessage);
      MqttMessagePubrel m = new MqttMessagePubrel.initWithPubRecMessage(mpr);
      _mqttConnection.sendMessageToBroker(m, debugMessage);
      _resetTimer();

      return m.len;
    }
    /**
     * handlePubRel
     * handle PUBREL message => send PUBCOMP
     */
    int _handlePubRel(data) {
      MqttMessagePubcomp m = new MqttMessagePubcomp.initWithPubRelMessage(new MqttMessagePubrel.decode(data, debugMessage));
      _mqttConnection.sendMessageToBroker(m, debugMessage);
      _resetTimer();

      return m.len;
    }

    /**
     * handlePubComp
     * handle PUBCOMP message => mark the publish as completed
     */
    int _handlePubComp(data) {
      MqttMessagePubcomp m = new MqttMessagePubcomp.decode(data, debugMessage);
      _completeMessage(m, "PUBCOMP");

      return m.len;
    }

    /**
     * handlePingReq
     * handle ping message => send PINGRESP
     */
    int _handlePingReq() {
      _mqttConnection.sendMessageToBroker(new MqttMessagePingResp(), debugMessage);
      _resetTimer();
      return 2;
    }

    void _resetTimer() {
      _liveTimer.cancel();
      _liveTimer = new Timer(const Duration(seconds:25), _live);
    }

    /**
     * live
     * send a PINGREQ message to the broker
     */
    void _live(){
      _mqttConnection.sendMessageToBroker(new MqttMessagePingReq(), debugMessage);
      _resetTimer();
    }
}
