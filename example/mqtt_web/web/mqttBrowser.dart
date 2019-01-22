import 'dart:html';
import 'package:mqtt/mqtt_shared.dart';
import 'package:mqtt/mqtt_connection_html_websocket.dart';

const query = querySelector;

class MqttBrowser {

  MqttClient c;
  static num subID;
  num _msgID = 0;

  void connectToBroker() {
    InputElement brokerUrl = query("#txt-broker-url");
    print("connecting to ${brokerUrl.value}");
    MqttConnectionHtmlWebSocket mqttCnx = new MqttConnectionHtmlWebSocket.setOptions(brokerUrl.value, "mqttv3.1");
    c = new MqttClient(mqttCnx,clientID: "browser", qos: QOS_1);

    c.connect(MqttBrowser.onConnectionLost)
      .then((c) => MqttBrowser.onConnected() );

  }

  void disconnectFromBroker() {

    if (c != null) {
      c.disconnect();
      ButtonElement btnConnect = query("#btn-connect");
      btnConnect.disabled = false;

      ButtonElement btnDisconnect = query("#btn-disconnect");
      btnDisconnect.disabled = true;

    }
  }

  void subscribe() {
    InputElement topic = query("#txt-subscribe-topic");
    print("subscribing to ${topic.value}");
    if (c != null) {
      c.subscribe(topic.value, QOS_1, MqttBrowser.onSubscribeData)
          .then( (s) => onSubscribed(s));
    }
  }
  void unsubscribe() {
    InputElement topic = query("#txt-subscribe-topic");
    print("unsubscribing from ${topic.value}");
    if (c != null) {
      c.unsubscribe(topic.value, subID)
          .then( (s) => onUnsubscribed());
    }
  }

  void publish() {
    InputElement topic = query("#txt-publish-topic");
    InputElement message = query("#txt-publish-msg");
    print("publishing ${message.value} to to ${topic.value}");
    if (c != null) {
      c.publish(topic.value, message.value, _msgID++, QOS_1, false)
          .then( (m) => print("Message ${m.messageID} published") );
    }
  }

  static void onSubscribed(s) {
    print("Subscription done - ID: ${s.messageID} - Qos: ${s.grantedQoS}");
    subID = s.messageID;
    ButtonElement btnSubscribe = query("#btn-subscribe");
    btnSubscribe.disabled = true;

    ButtonElement btnUnsubscribe = query("#btn-unsubscribe");
    btnUnsubscribe.disabled = false;

  }
  static void onSubscribeData(topic, data) {
    print("[$topic] $data");
    addMessageToList(topic, data);
  }

  static void onUnsubscribed() {
    print("Subscription cancelled");

    ButtonElement btnSubscribe = query("#btn-subscribe");
    btnSubscribe.disabled = false;

    ButtonElement btnUnsubscribe = query("#btn-unsubscribe");
    btnUnsubscribe.disabled = true;

  }

  static void onConnected() {
    print("Connected !");
    ButtonElement btnConnect = query("#btn-connect");
    btnConnect.disabled = true;

    ButtonElement btnDisconnect = query("#btn-disconnect");
    btnDisconnect.disabled = false;

    ButtonElement btnSubscribe = query("#btn-subscribe");
    btnSubscribe.disabled = false;

    ButtonElement btnPublish = query("#btn-publish");
    btnPublish.disabled = false;

  }
  static void onConnectionLost() {
    print("Connection to broker lost");
  }


  static void addMessageToList(topic, data){
    StringBuffer msg = new StringBuffer();
    msg.writeAll(["[", topic, "] : ", data]);

    DivElement itemContainer = query("#subMsgs");

    DivElement subMsgElement = new Element.tag("div");
    subMsgElement.classes.add("subMsg");
    subMsgElement.text = msg.toString();

    itemContainer.children.add(subMsgElement);
  }
}
main() {
  var myHeading = new Element.html("<h2>Mqtt Client test</h2>");
  document.body.children.add(myHeading);

  var brokerHostLbl = new Element.html("<strong>Broker Url:</strong>");
  document.body.children.add(brokerHostLbl);

  InputElement brokerUrl = new Element.tag("input");
  brokerUrl.id = "txt-broker-url";
  //brokerUrl.placeholder = "Enter the broker url";
  brokerUrl.value = "ws://127.0.0.1:8080";
  document.body.children.add(brokerUrl);

  ButtonElement btnConnect = new Element.tag("button");
  btnConnect.id = "btn-connect";
  btnConnect.text = "Connect";
  document.body.children.add(btnConnect);


  MqttBrowser mqtt = new MqttBrowser();

  btnConnect.onClick.listen( (e) => mqtt.connectToBroker());

  ButtonElement btnDisconnect = new Element.tag("button");
  btnDisconnect.id = "btn-disconnect";
  btnDisconnect.text = "Disconnect";
  btnDisconnect.disabled = true;
  document.body.children.add(btnDisconnect);

  btnDisconnect.onClick.listen( (e) => mqtt.disconnectFromBroker());

  document.body.children.add(new Element.html("</br>"));

  var subscribeLbl = new Element.html("<strong>Subscribe topic:</strong>");
  document.body.children.add(subscribeLbl);

  InputElement subscribeTopic = new Element.tag("input");
  subscribeTopic.id = "txt-subscribe-topic";
  subscribeTopic.placeholder = "Enter the topic to subscribe to";
  document.body.children.add(subscribeTopic);

  ButtonElement btnSubscribe = new Element.tag("button");
  btnSubscribe.id = "btn-subscribe";
  btnSubscribe.text = "Subscribe";
  btnSubscribe.disabled = true;
  document.body.children.add(btnSubscribe);

  btnSubscribe.onClick.listen( (e) => mqtt.subscribe());

  ButtonElement btnUnsubscribe= new Element.tag("button");
  btnUnsubscribe.id = "btn-unsubscribe";
  btnUnsubscribe.text = "Unsubscribe";
  btnUnsubscribe.disabled = true;
  document.body.children.add(btnUnsubscribe);

  btnUnsubscribe.onClick.listen( (e) => mqtt.unsubscribe());


  var publishLbl = new Element.html("<strong>Publish topic:</strong>");
  document.body.children.add(publishLbl);

  InputElement publishTopic = new Element.tag("input");
  publishTopic.id = "txt-publish-topic";
  publishTopic.placeholder = "Enter the topic to publish to";
  document.body.children.add(publishTopic);

  var publishMessageLbl = new Element.html("<strong>Message:</strong>");
  document.body.children.add(publishMessageLbl);

  InputElement publishMessage = new Element.tag("input");
  publishMessage.id = "txt-publish-msg";
  publishMessage.placeholder = "Enter the message to publish";
  document.body.children.add(publishMessage);


  ButtonElement btnPublish = new Element.tag("button");
  btnPublish.id = "btn-publish";
  btnPublish.text = "Publish";
  btnPublish.disabled = true;
  document.body.children.add(btnPublish);

  btnPublish.onClick.listen( (e) => mqtt.publish());


  DivElement subMsgList = new Element.tag("div");
  subMsgList.id = "subMsgs";
  subMsgList.style.width = "300px";
  subMsgList.style.border = "1px solid black";
  subMsgList.innerHtml = "&nbsp";
  document.body.children.add(subMsgList);


}
