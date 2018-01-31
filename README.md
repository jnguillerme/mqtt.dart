Mqtt
=====
This is an mqtt client written in Dart. 
It can be used in the browser (over websocket) or the VM (over socker or websocket). 
 
See http://mqtt.org/ for details on mqtt protocol.


Usage
-------

Create a connection over websocket:
~~~
var mqttCnx = new MqttConnectionIOWebSocket.setOptions("ws://127.0.0.1/8080");
~~~
    
Create a connection over socket:
~~~
var mqttCnx = new MqttConnectionIOSocket.setOptions(host: "127.0.0.1", port: 8083);
~~~

Create mqtt client:
~~~
MqttClient c = new MqttClient(mqttCnx, clientID: "MyClientID", qos: QOS_1);
~~~

Set a will (must be done before connecting to the broker):
~~~
c.setWill("MyWillTopic", "MyWillPayload", QOS_1, 0);
~~~

Connect to broker:
~~~
c.connect(onConnectionLost)
    .then( (c)=> onConnected(c) ) 
    .catchError((e) => print("Error: $e"), test: (e) => e is SocketException)  
    .catchError((mqttErr) => print("Error: $mqttErr")
);      
~~~

Publish a message:
~~~
c.publish("MyTopic", "MyMessage", 1, QOS_1, 0)
    .then( (m) => print("Message ${m.messageID} published"); );
~~~

Subscribe to a topic:
~~~
c.subscribe("MyTopic", QOS_1, onMessage)
  	.then( (s) => print("Subscription done - ID: ${s.messageID} - Qos: ${s.grantedQoS}") );
~~~

Unsubscribe:
~~~
c.unsubscribe("MyTopic", s.messageID)
	.then( (u) => print("Unsubscribed from subscription ${u.messageID}") );
~~~

Disconnect:
~~~
c.disconnect();    
~~~ 
     
VM Example
-----------

See `example/mqtt_sub/` for a sample mqtt publish and `example/mqtt_pub/` for a sample subscribe.
Available options can be displayed through:
* `dart mqtt_sub.dart -h`
* `dart mqtt_pub.dart -h`

Web Example
-----------
	
See `example/mqtt_web` for a sample web page connecting, subscribing and publishing mqtt messages

    
Testing
----------
Testing was done using the mosquitto broker (http://mosquitto.org/).
A mosquitto test server is available at http://test.mosquitto.org/.

Websocket testing was done through mqtt_ws_bridge.dart.