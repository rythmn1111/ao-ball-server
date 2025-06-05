const { connect, createDataItemSigner } = require('@permaweb/aoconnect');
const { readFileSync } = require('fs');

const wallet = JSON.parse(readFileSync('wallet.json').toString());
const leaderboardProcessId = 'eyDQaQlKhHteWQTJU6xn_v8_3Ga7B4Xk16gcNgNXfjw';

const ao = connect({
  MODE: 'legacy',
  CU_URL: 'https://cu.ao-testnet.xyz',
  MU_URL: 'https://mu.ao-testnet.xyz',
  GATEWAY_URL: 'https://arweave.net',
});

async function fetchLeaderboard() {
  const tags = [
    { name: 'Action', value: 'GetLeaderboard' },
    { name: 'All', value: 'true' }
  ];
  const messageId = await ao.message({
    process: leaderboardProcessId,
    data: '',
    signer: createDataItemSigner(wallet),
    tags,
  });
  console.log('⏳ Waiting for leaderboard result...');
  await new Promise(res => setTimeout(res, 2000));
  const result = await ao.result({ process: leaderboardProcessId, message: messageId });
  try {
    const leaderboard = JSON.parse(result.Output);
    console.log('🏆 Leaderboard:', leaderboard);
  } catch (e) {
    console.log('Raw result:', result.Output);
    console.error('❌ Failed to parse leaderboard:', e);
  }
}

fetchLeaderboard(); 