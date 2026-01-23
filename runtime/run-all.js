const { execSync } = require("child_process");

function run(cmd, title) {
  console.log("\n==== " + title + " ====");
  execSync(cmd, { stdio: "inherit" });
}

run("powershell -ExecutionPolicy Bypass -File ./master-test.ps1", "MASTER TEST");

run("node ./multi-agent-system.js", "MULTI AGENT SYSTEM");

run("node ./nft/zora-mint.js", "ZORA NFT MINT");

console.log("\n✅ TUTTO COMPLETATO");
