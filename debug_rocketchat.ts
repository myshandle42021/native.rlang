// debug_rocketchat.ts - Test the exact same request the system makes
import https from 'https';

// Disable SSL verification for testing
const agent = new https.Agent({
  rejectUnauthorized: false
});

async function testRocketChatHTTPS() {
  console.log('🔍 Testing HTTPS connection to RocketChat...');
  
  try {
    const response = await fetch('https://103.6.170.126:3000/api/v1/chat.postMessage', {
      method: 'POST',
      // @ts-ignore - Node.js specific option
      agent: agent,
      headers: {
        'Authorization': 'Bearer eLnkYUCcVVOx2qFivg14ekSiQlOveqDCyqo7c4CTj9p',
        'X-Auth-Token': 'eLnkYUCcVVOx2qFivg14ekSiQlOveqDCyqo7c4CTj9p',
        'X-User-Id': 'AoMQzuqnFR4ENdevY',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        roomId: 'GENERAL',
        text: 'Test message from ROL3 debug'
      })
    });
    
    console.log('✅ HTTPS Response status:', response.status);
    console.log('✅ HTTPS Response:', await response.text());
    return true;
  } catch (error) {
    console.log('❌ HTTPS Fetch error:', error.message);
    console.log('❌ Error details:', error);
    return false;
  }
}

async function testRocketChatHTTP() {
  console.log('🔍 Testing HTTP connection to RocketChat...');
  
  try {
    const response = await fetch('http://103.6.170.126:3000/api/v1/chat.postMessage', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer eLnkYUCcVVOx2qFivg14ekSiQlOveqDCyqo7c4CTj9p',
        'X-Auth-Token': 'eLnkYUCcVVOx2qFivg14ekSiQlOveqDCyqo7c4CTj9p',
        'X-User-Id': 'AoMQzuqnFR4ENdevY',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        roomId: 'GENERAL',
        text: 'Test message from ROL3 debug HTTP'
      })
    });
    
    console.log('✅ HTTP Response status:', response.status);
    console.log('✅ HTTP Response:', await response.text());
    return true;
  } catch (error) {
    console.log('❌ HTTP Fetch error:', error.message);
    return false;
  }
}

async function testRocketChatInfo() {
  console.log('🔍 Testing RocketChat info endpoint...');
  
  try {
    // Test HTTP info endpoint
    const response = await fetch('http://103.6.170.126:3000/api/v1/info');
    console.log('📊 Info Response status:', response.status);
    console.log('📊 Info Response:', await response.text());
  } catch (error) {
    console.log('❌ Info endpoint error:', error.message);
  }
}

async function runAllTests() {
  console.log('🚀 Starting RocketChat connectivity tests...\n');
  
  // Test 1: Info endpoint
  await testRocketChatInfo();
  console.log('\n---\n');
  
  // Test 2: HTTP connection
  const httpWorks = await testRocketChatHTTP();
  console.log('\n---\n');
  
  // Test 3: HTTPS connection
  const httpsWorks = await testRocketChatHTTPS();
  
  console.log('\n🎯 Test Results:');
  console.log(`HTTP works: ${httpWorks ? '✅' : '❌'}`);
  console.log(`HTTPS works: ${httpsWorks ? '✅' : '❌'}`);
  
  if (httpWorks && !httpsWorks) {
    console.log('\n💡 Recommendation: Use HTTP instead of HTTPS');
  } else if (!httpWorks && !httpsWorks) {
    console.log('\n💡 Recommendation: Check RocketChat server is running');
  }
}

runAllTests().catch(console.error);
