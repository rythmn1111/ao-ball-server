const mqtt = require('mqtt');
const express = require('express');
const { readFileSync } = require('fs');
const { connect, createDataItemSigner } = require('@permaweb/aoconnect');

// ========== AO CONFIG ==========
const wallet = JSON.parse(readFileSync("wallet.json").toString());
const processId = "vBv8fQ6FlqZkvKlGrWwt8ngBPpVU0ypW_2GcvbOdLdY"; // replace with your AO process ID

const ao = connect({
  MODE: "legacy",
  CU_URL: "https://cu.ao-testnet.xyz",
  MU_URL: "https://mu.ao-testnet.xyz",
  GATEWAY_URL: "https://arweave.net",
});

async function sendLuaToAO(processId, luaCode, tags = []) {
  const allTags = [{ name: "Action", value: "Eval" }, ...tags];
  const messageId = await ao.message({
    process: processId,
    data: luaCode,
    signer: createDataItemSigner(wallet),
    tags: allTags,
  });

  await new Promise((res) => setTimeout(res, 100));
  const result = await ao.result({ process: processId, message: messageId });
  result.id = messageId;
  return result;
}

// ========== MQTT + EXPRESS SETUP ==========
const app = express();
const PORT = 3000;

const MQTT_BROKER = 'mqtt://51.68.237.246';
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

client.on('message', async (topic, message) => {
  if (topic === MQTT_TOPIC) {
    try {
      const data = JSON.parse(message.toString());
      console.log(`📥 MQTT:`, data);

      // Construct Lua append code
      const luaCode = `table.insert(throws, { id = "${data.id}",height = ${data.height}, speed = ${data.speed}, strength = ${data.strength} })`;

      // Send to AO
      const result = await sendLuaToAO(processId, luaCode);
      console.log(`📤 Sent to AO (ID: ${result.id})`);
    } catch (err) {
      console.error('❌ Message Error:', err);
    }
  }
});

app.get('/', (req, res) => {
  res.send('MQTT → AO bridge running');
});

app.listen(PORT, () => {
  console.log(`🚀 Server running at http://localhost:${PORT}`);
});

