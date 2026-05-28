import http from 'k6/http';
import { check, sleep } from 'k6';

// k6 Load Testing Options
export const options = {
  stages: [
    { duration: '10s', target: 50 },  // Ramp up to 50 virtual users (VUs)
    { duration: '20s', target: 100 }, // Simulate peak load with 100 concurrent VUs
    { duration: '10s', target: 0 },   // Ramp down to 0 users
  ],
  thresholds: {
    // p95 response time must stay strictly under 500ms
    http_req_duration: ['p(95)<500'],
    // Request failure rate must be under 1%
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = 'http://localhost:4101/api';

export default function () {
  // 1. Simulate reading registered sensors snapshot
  const resSensors = http.get(`${BASE_URL}/sensors`);
  check(resSensors, {
    'GET /sensors returns 200': (r) => r.status === 200,
    'GET /sensors p95 under 500ms': (r) => r.timings.duration < 500,
  });

  sleep(0.5); // 500ms pacing delay between user actions

  // 2. Simulate dashboard loading current water level readings
  const resWater = http.get(`${BASE_URL}/water-levels/current`);
  check(resWater, {
    'GET /water-levels/current returns 200': (r) => r.status === 200,
    'GET /water-levels/current p95 under 500ms': (r) => r.timings.duration < 500,
  });

  sleep(0.5);

  // 3. Simulate active sensor posting telemetries (POST /iot/ingest)
  const payload = JSON.stringify({
    sensorId: 'RAIN-SIM-999',
    rainfall: Math.round((Math.random() * 30) * 10) / 10,
    batteryLevel: 92,
    connectivity: 'ONLINE',
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const resIngest = http.post(`${BASE_URL}/iot/ingest`, payload, params);
  check(resIngest, {
    'POST /iot/ingest returns 200 or 201': (r) => r.status === 200 || r.status === 201,
    'POST /iot/ingest p95 under 500ms': (r) => r.timings.duration < 500,
  });

  sleep(1.0); // 1s cooldown between iterations
}
