# ao-ball

A bridge server that connects MQTT messages to the AO (Arweave Orchestrator) process, enabling real-time data forwarding from IoT devices or other sources to the AO network using Lua scripting.

## Features
- Listens to MQTT messages on a configurable topic.
- Forwards received data to an AO process by constructing and sending Lua code.
- Includes two server variants:
  - `test-server-2.js`: Full implementation with AO integration.
  - `test-server-1.js`: Basic MQTT listener with a placeholder for AO logic.
- Health check endpoint via Express.

## Prerequisites
- Node.js (v14 or higher recommended)
- An AO process ID (from the AO testnet)
- A valid AO wallet JSON file (`wallet.json`)

## Installation
1. Clone the repository:
   ```bash
   git clone <your-repo-url>
   cd ao-ball-server
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Place your AO wallet file as `wallet.json` in the project root.

## Configuration
- **AO Process ID:**
  - In `test-server-2.js`, replace the `processId` variable with your AO process ID.
- **MQTT Broker:**
  - Default is set to `mqtt://51.68.237.246` and topic `ball/ao`. Change as needed in the server files.

## Usage
### Run the main server (with AO integration):
```bash
node test-server-2.js
```
- The server will:
  - Connect to the MQTT broker and subscribe to the topic.
  - On receiving a message, parse the data and send it to the AO process as a Lua table insert.
  - Expose a health check at `http://localhost:3000/`.

### Run the basic MQTT listener:
```bash
node test-server-1.js
```
- This version only logs received MQTT messages and includes a placeholder for AO integration.

## Example MQTT Message
Send a JSON message to the topic (e.g., using MQTT Explorer or another client):
```json
{
  "id": "device123",
  "height": 10,
  "speed": 5,
  "strength": 7
}
```

## Security Note
- **Do NOT commit your `wallet.json` to public repositories.**
- Treat your wallet file as a secret; it provides access to your AO process.

## License
ISC

## Acknowledgments
- [Arweave AO Testnet](https://ao.arweave.dev/)
- [MQTT](https://mqtt.org/)
- [Express](https://expressjs.com/) 