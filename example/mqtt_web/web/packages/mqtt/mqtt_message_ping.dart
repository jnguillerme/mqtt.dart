part of mqtt_shared;

/**
 * MqttMessagePingReq
 * 
 * MQTT PINGREQ message
 * 
 */
class MqttMessagePingReq extends MqttMessage {
  MqttMessagePingReq() :super(PINGREQ);
}

/**
 * MqttMessagePingReq
 * 
 * MQTT PINGRESP message
 * 
 */
class MqttMessagePingResp extends MqttMessage {
  MqttMessagePingReq() :super(PINGRESP);
} 