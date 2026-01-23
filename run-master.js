const { execSync } = require("child_process");

execSync("powershell -ExecutionPolicy Bypass -File ./master-test.ps1", {
  stdio: "inherit"
});
