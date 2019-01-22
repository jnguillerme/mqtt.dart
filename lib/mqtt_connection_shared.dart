part of mqtt_shared;

abstract class VirtualMqttConnection {

  Future connect();
  handleConnectError(e);

  sendMessageToBroker(MqttMessage m, [bool debugMessage = false]) {
    m.encode();

    if (debugMessage) {
      print(">>> ${m.toString()}");
    }
    privateSendMessageToBroker(m);
  }

  privateSendMessageToBroker(MqttMessage m);
  setConnection(cnx);
  startListening(_processData, _handleDone, _handleError);
  close();
}

