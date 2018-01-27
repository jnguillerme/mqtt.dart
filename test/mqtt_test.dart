import 'package:test/test.dart';

import '../lib/mqtt_shared.dart';

class MqttMessagePublishMatcher extends Matcher {
  MqttMessagePublish _expected;
  
  MqttMessagePublishMatcher(this._expected);
  
  bool matches(MqttMessagePublish actual, Map mapState) {
    return (_expected == actual);
  }
  
   describe(Description description) {
     return description.add("MqttMessage");
   }
}

main() {

  testPublish("MqttMessagePublish QOS(0) - no retain", QOS_0, 0);
  testPublish("MqttMessagePublish QOS(1) - no retain", QOS_1, 0);
  testPublish("MqttMessagePublish QOS(2) - no retain", QOS_2, 0);

  testPublish("MqttMessagePublish QOS(0) - retain", QOS_0, 1);
  testPublish("MqttMessagePublish QOS(1) - retain", QOS_1, 1);
  testPublish("MqttMessagePublish QOS(2) - retain", QOS_2, 1);
  
  test("MqttMessagePuback", () {
    MqttMessagePublish m1 = new MqttMessagePublish.setOptions("topicTEST", "payloadTEST", 12345, QOS_0, 0);
    MqttMessagePuback m2 = new MqttMessagePuback.initWithPublishMessage(m1);

    expect(m2.messageID, equals(m1.messageID));
  });
  
  test("MqttMessagePubRec", () {
    MqttMessagePublish m1 = new MqttMessagePublish.setOptions("topicTEST", "payloadTEST", 12345, QOS_0, 0);
    MqttMessagePubrec m2 = new MqttMessagePubrec.initWithPublishMessage(m1);

    expect(m2.messageID, equals(m1.messageID));
  });
  
  test("MqttMessagePubRel", () {
    MqttMessagePubrec m1 = new MqttMessagePubrec(1, 2);
    MqttMessagePubrel m2 = new MqttMessagePubrel.initWithPubRecMessage(m1);

    expect(m2.messageID, equals(m1.messageID));
  });

  test("MqttMessagePubComp", () {
    MqttMessagePubrel m1 = new MqttMessagePubrel(1, 2);
    MqttMessagePubcomp m2 = new MqttMessagePubcomp.initWithPubRelMessage(m1);

    expect(m2.messageID, equals(m1.messageID));
  });

}

testPublish(String testName, num QoS, int retain) {
  test(testName, () {
    MqttMessagePublish m1 = new MqttMessagePublish.setOptions("topicTEST", "payloadTEST", 1, QoS, retain);
    m1.encode();    
    MqttMessagePublish m2 = new MqttMessagePublish.decode(m1.buf);
    
    expect(m2, new MqttMessagePublishMatcher(m1));

    MqttMessagePublish ml1 = new MqttMessagePublish.setOptions("topicTEST", "payloadTEST very long very long very long very long very long very long very long very long very long very long very long very long very long very long very long very long very long", 1, QoS, retain);
    ml1.encode();    
    MqttMessagePublish ml2 = new MqttMessagePublish.decode(ml1.buf);
    
    expect(ml2, new MqttMessagePublishMatcher(ml1));
  });
}
