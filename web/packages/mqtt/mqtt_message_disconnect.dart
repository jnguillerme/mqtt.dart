part of mqtt_shared;

/**
 * MqttMessageDisconnect
 * 
 * MQTT DISCONNECT message
 * 
 */
class MqttMessageDisconnect extends MqttMessage {
  MqttMessageDisconnect() : super(DISCONNECT);  
  encodeVariableHeader() {}
}