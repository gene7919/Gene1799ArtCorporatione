module.exports = {
  apps: [{
    name: 'zora-autopilot',
    script: 'revenue-monitor.js',
    cwd: 'C:\\\\SuiteV17\\\\zora_autopilot',
    env: { PORT: '8788', NODE_ENV: 'production' },
    max_restarts: 5,
    restart_delay: 5000
  }]
};
