const mqtt = require('mqtt');
const express = require('express');

const app = express();
const PORT = 3000;

// MQTT setup
const MQTT_BROKER = 'mqtt://51.68.237.246'; // or use your own broker IP
const MQTT_TOPIC = 'ball/ao';

const client = mqtt.connect(MQTT_BROKER);

client.on('connect', () => {
  console.log(`✅ Connected to MQTT broker: ${MQTT_BROKER}`);
  client.subscribe(MQTT_TOPIC, (err) => {
    if (err) {
      console.error('❌ MQTT Subscription Error:', err);
    } else {
      console.log(`📡 Subscribed to topic: ${MQTT_TOPIC}`);
    }
  });
});

client.on('message', (topic, message) => {
  if (topic === MQTT_TOPIC) {
    try {
      const data = JSON.parse(message.toString());
      console.log(`📥 Received on "${topic}":`, data);
      // TODO: Forward to AO process using your `runLua()` logic
    } catch (e) {
      console.error('❌ Failed to parse message:', e);
    }
  }
});

// Express endpoint (optional, for health check or future API)
app.get('/', (req, res) => {
  res.send('MQTT Listener Running');
});

app.listen(PORT, () => {
  console.log(`🚀 Express server running on http://localhost:${PORT}`);
});

