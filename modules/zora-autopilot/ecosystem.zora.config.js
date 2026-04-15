module.exports = {
  apps: [
    {
      name: "zora-autopilot",
      script: "C:\\SuiteV17\\modules\\zora-autopilot\\revenue-monitor.js",
      cwd: "C:\\SuiteV17\\modules\\zora-autopilot",
      instances: 1,
      exec_mode: "fork",
      autorestart: true,
      watch: false,
      max_restarts: 10,
      restart_delay: 3000,
      env: {
        NODE_ENV: "production",
        PORT: "8788",
        ZORA_MONITOR_PORT: "8788",
        WALLET: "0x0d08e9123ad0ca2a787088350d30853a941332c1"
      },
      out_file: "C:\\SuiteV17\\logs\\zora-autopilot.log",
      error_file: "C:\\SuiteV17\\logs\\zora-autopilot-error.log",
      time: true
    }
  ]
};
