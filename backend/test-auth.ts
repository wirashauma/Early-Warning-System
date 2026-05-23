const axios = require('axios');

async function testRegister() {
  try {
    const response = await axios.post('http://localhost:4001/api/auth/register', {
      email: 'test@example.com',
      password: 'password123',
      name: 'Test User'
    });
    console.log('✅ Register successful:', response.data);
  } catch (error) {
    console.error('❌ Register failed:', error.response?.data || error.message);
  }
}

async function testLogin() {
  try {
    const response = await axios.post('http://localhost:4001/api/auth/login', {
      email: 'test@example.com',
      password: 'password123'
    });
    console.log('✅ Login successful:', response.data);
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
  }
}

async function testGoogleLogin() {
  try {
    // This would normally use a real Firebase ID token
    const response = await axios.post('http://localhost:4001/api/auth/google-login', {
      idToken: 'fake_token_for_testing'
    });
    console.log('✅ Google login successful:', response.data);
  } catch (error) {
    console.error('❌ Google login failed:', error.response?.data || error.message);
  }
}

async function runTests() {
  console.log('Testing authentication endpoints...\n');

  console.log('1. Testing register...');
  await testRegister();

  console.log('\n2. Testing login...');
  await testLogin();

  console.log('\n3. Testing Google login (will fail with fake token)...');
  await testGoogleLogin();
}

runTests();