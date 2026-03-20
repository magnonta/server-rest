// Health Check Test
// Teste simples para verificar se a API está respondendo
// Uso: k6 run k6/scripts/00-health-check.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { BASE_URL } from '../modules/config.js';

export const options = {
  vus: 1,
  duration: '10s',
  thresholds: {
    'http_req_duration': ['p(95)<200'],
    'http_req_failed': ['rate<0.01'],
  },
};

export default function () {
  const response = http.get(BASE_URL);
  
  check(response, {
    'status é 200': (r) => r.status === 200,
    'resposta contém ServeRest': (r) => r.status !== 0 && r.body && r.body.includes('ServeRest'),
  });
  
  sleep(1);
}
