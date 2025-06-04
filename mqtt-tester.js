const mqtt = require('mqtt');

const MQTT_BROKER = 'mqtt://51.68.237.246';
const MQTT_TOPIC = 'ball/ao';

const client = mqtt.connect(MQTT_BROKER);

client.on('connect', () => {
  console.log(`✅ Connected to MQTT broker: ${MQTT_BROKER}`);
  setInterval(() => {
    const dummyData = {
      id: `${Math.floor(Math.random() * 1000)}`,
      height: Math.floor(Math.random() * 100),
      speed: Math.floor(Math.random() * 20),
      strength: Math.floor(Math.random() * 10)
    };
    client.publish(MQTT_TOPIC, JSON.stringify(dummyData), {}, (err) => {
      if (err) {
        console.error('❌ Publish error:', err);
      } else {
        console.log('📤 Sent:', dummyData);
      }
    });
  }, 4000);
}); 