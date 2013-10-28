part of mqtt_shared;

class MqttOptions {
  static Map<String, String> optionList = {
                        'mqtt_broker' :['host','port', 'user', 'password'],
                        'mqtt_options': ['debug', 'qos','clientID','cleanSession','topic', 'payload', 'keepAlive'],
                        'mqtt_will_options': ['topic','payload','qos','retain']
  };
  
  Config _config; 
  bool debugMessage = false;
  bool cleanSession = true;
  String host = '127.0.0.1';
  num port= 1883;
  String clientID = "mqtt_dart";
  num keepAlive = 60;
  String topic;
  String payload;
  int QoS = QOS_0;
  String user = "";
  String password = "";
  
  String willTopic = null;
  String willPayload = null;
  int willQoS = QOS_0;
  bool willRetain = false;

  MqttOptions.initFromConfig(String configFile)  {    
    File cfgFile = new File(configFile);
    _config = Config.readFileSync(cfgFile);

    optionList.forEach((k,v) =>  processOptionsForSection(k, v) );
  }
  
  void processOptionsForSection(section, options) {
    options.forEach( (v) => setOption(section + "." + v, section, v ));
    
  }
  bool setOption(String option, String section, String param) {
    bool valueUsed = true;
    String value = _config.get(section, param);  
    print ("[${section}] ${param} ");
    print ("=> ${value}");
    
    if (value != null && section.contains('mqtt_')) {
      switch (option) {
        case 'mqtt_options.debug': 
          valueUsed = false;
          debugMessage = true;
          break;
        case 'mqtt_options.cleanSession': 
          valueUsed = false;
          cleanSession = false;
          break;
        case 'mqtt_broker.host': 
          host = value;
          break;
        case 'mqtt_broker.port': 
           port = int.parse(value);
          break;
        case 'mqtt_options.clientID':
          clientID = value;
          break;
        case 'mqtt_options.keepAlive':
           keepAlive = int.parse(value);
          break;
        case 'mqtt_options.topic': 
          topic = value;
          break;
        case 'mqtt_options.payload': 
          payload = value;
          break;
        case 'mqtt_options.qos': 
          QoS = int.parse(value);
          break;
        case 'mqtt_broker.user': 
          user = value;
          break;
        case 'mqtt_broker.password': 
          password = value;
          break;
        case 'mqtt_will_options.payload': 
          willPayload = value;
          break;
        case 'mqtt_will_options.qos': 
          willQoS = int.parse(value);
          break;
        case 'mqtt_will_options.retain': 
          valueUsed = false;
          willRetain = true;
          break;
        case 'mqtt_will_options.topic':
          willTopic = value;
          break;
        default: 
            print("Unknown option $option");
            break;
      }
    }    
    return valueUsed;
  }
    
}